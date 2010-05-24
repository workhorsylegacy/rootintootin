/*
# Copyright 2010 Matthew Brennan Jones
# Copyright 2009 Facebook
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#	 http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
*/
//"""A level-triggered I/O loop for non-blocking sockets."""

module dornado.ioloop;

private import tango.sys.Pipe;
private import tango.stdc.posix.stdio;
private import tango.stdc.posix.fcntl;
private import tango.io.model.IConduit;

private import tango.io.selector.EpollSelector;
private import tango.io.selector.SelectSelector;
private import tango.net.device.Socket;
private import tango.net.InternetAddress;

private import tango.time.Clock;
private import tango.io.Stdout;
private import tango.stdc.stringz;

public import tango.io.Stdout;
public import language_helper;


private float min(float a, float b) {
	return a >= b ? a : b;
}

class EventPair {
	public ISelectable.Handle fd;
	public uint event;

	public this(ISelectable.Handle fd, uint event) {
		this.fd = fd;
		this.event = event;
	}
}

// Start Temporary stub objects
class OSError : Exception {
	public this(string text, ushort status) {
		super("");
	}
}

class IOError : Exception {
	public this(string text, ushort status) {
		super("");
	}
}

class KeyboardInterrupt : Exception {
	public this(string text, ushort status) {
		super("");
	}
}

class SystemExit : Exception {
	public this(string text, ushort status) {
		super("");
	}
}
// End Temporary stub objects


class IOLoop {
	private BasePoll _impl;
	private void delegate(ISelectable.Handle fd, uint events)[ISelectable.Handle] _handlers;
	private EventPair[ISelectable.Handle] _events;
	private void delegate()[] _callbacks;
	private _Timeout[] _timeouts;
	private bool _running = false;

	private FILE* _waker_reader = null;
	private FILE* _waker_writer = null;

	// Constants from the epoll module
	public static const uint _EPOLLIN = 0x001;
	public static const uint _EPOLLPRI = 0x002;
	public static const uint _EPOLLOUT = 0x004;
	public static const uint _EPOLLERR = 0x008;
	public static const uint _EPOLLHUP = 0x010;
	public static const uint _EPOLLRDHUP = 0x2000;
	public static const uint _EPOLLONESHOT = (1 << 30);
	public static const uint _EPOLLET = (1 << 31);

	// Our events map exactly to the epoll events
	public static const uint NONE = 0;
	public static const uint READ = _EPOLLIN;
	public static const uint WRITE = _EPOLLOUT;
	public static const uint ERROR = _EPOLLERR | _EPOLLHUP | _EPOLLRDHUP;

	private static IOLoop _instance = null;
	public static bool use_epoll = false;

	public static BasePoll get_poll() {
		if(use_epoll)
			return new _EPoll();
		else
			return new _Select();
	}

	public static IOLoop instance() {
		Stdout("IOLoop.instance").newline.flush;
		if(_instance is null)
			_instance = new IOLoop();
		return _instance;
	}

	public this(BasePoll impl=null) {
		Stdout("IOLoop.__init__").newline.flush;
		this._impl = impl ? impl : get_poll();

		// Create a pipe that we send bogus data to, when we want to wake
		// the I/O loop when it is idle
		auto pipe = new Pipe();
		ISelectable.Handle r = pipe.sink.fileHandle;
		ISelectable.Handle w = pipe.source.fileHandle;
		this._set_nonblocking(r);
		this._set_nonblocking(w);
		this._waker_reader = fdopen(cast(int)r, "r");
		this._waker_writer = fdopen(cast(int)w, "w");
		this.add_handler(r, &this._read_waker, this.WRITE);
	}

	public void add_handler(ISelectable.Handle fd, void delegate(ISelectable.Handle fd, uint events) handler, uint events) {
		//"""Registers the given handler to receive the given events for fd."""
		Stdout("IOLoop.add_handler").newline.flush;
		this._handlers[fd] = handler;
		this._impl.register(fd, events | this.ERROR);
	}

	public void update_handler(ISelectable.Handle fd, uint events) {
		//"""Changes the events we listen for fd."""
		Stdout("IOLoop.update_handler").newline.flush;
		this._impl.modify(fd, events | this.ERROR);
	}

	public void remove_handler(ISelectable.Handle fd) {
		//"""Stop listening for events on fd."""
		Stdout("IOLoop.remove_handler").newline.flush;
		this._handlers.remove(fd);
		this._events.remove(fd);
		try {
			this._impl.unregister(fd);
		} catch(OSError err) {
//			logging.debug("Error deleting fd from IOLoop", exc_info=true);
		}
	}

	public void start(Socket sock) {
		//"""Starts the I/O loop.

		//The loop will run until one of the I/O handlers calls stop(), which
		//will make the loop stop after the current event iteration completes.
		//"""
		Stdout("IOLoop.start").newline.flush;
		this._running = true;
		while(true) {
			// Never use an infinite timeout here - it can stall epoll
			float poll_timeout = 0.2;

			// Prevent IO event starvation by delaying new callbacks
			// to the next iteration of the event loop.
			void delegate()[] callbacks = this._callbacks[];
			foreach(void delegate() callback ; callbacks) {
				// A callback can add or remove other callbacks
				if(Array!(void delegate()).contains(this._callbacks, callback)) {
					Array!(void delegate()).remove_item(this._callbacks, callback);
					this._run_callback(callback);
				}
			}

			if(this._callbacks.length > 0)
				poll_timeout = 0.0;

			if(this._timeouts.length > 0) {
				float now = Clock.now.unix.seconds;
				while(this._timeouts.length > 0 && this._timeouts[0].deadline <= now) {
					_Timeout timeout = Array!(_Timeout).pop(this._timeouts, 0);
					this._run_callback(timeout.callback);
				}
				if(this._timeouts.length > 0) {
					float milliseconds = this._timeouts[0].deadline - now;
					poll_timeout = min(milliseconds, poll_timeout);
				}
			}

			if(!this._running)
				break;

			EventPair[] event_pairs = null;
			try {
				event_pairs = this._impl.poll(sock, poll_timeout);
			} catch(Exception e) {
				if(e.msg == "Interrupted system call") {
//					logging.warning("Interrupted system call", exc_info=1);
					continue;
				} else {
					throw(e);
				}
			}

			// Update the waiting events with the new ones
			foreach(EventPair event_pair; event_pairs) {
				this._events[event_pair.fd] = event_pair;
			}

			// Pop one fd at a time from the set of pending fds and run
			// its handler. Since that handler may perform actions on
			// other file descriptors, there may be reentrant calls to
			// this IOLoop that update this._events
			while(this._events.length > 0) {
				ISelectable.Handle fd = this._events.keys[0];
				uint events = this._events[fd].event;
				this._events.remove(fd);

				try {
					this._handlers[fd](fd, events);
				} catch(KeyboardInterrupt e) {
					throw(e);
				} catch(OSError e) {
//					if(e[0] == errno.EPIPE) {
//						// Happens when the client closes the connection
 //				   } else {
//						logging.error("Exception in I/O handler for fd %d",
//									  item.fd, exc_info=true);
//					}
				} catch {
//					logging.error("Exception in I/O handler for fd %d",
//								  item.fd, exc_info=true);
				}
			}
		}
	}

	public void stop() {
		//"""Stop the loop after the current event loop iteration is complete."""
		Stdout("IOLoop.stop").newline.flush;
		this._running = false;
		this._wake();
	}

	public bool running() {
		//"""Returns true if this IOLoop is currently running."""
		Stdout("IOLoop.running").newline.flush;
		return this._running;
	}

	public _Timeout add_timeout(float deadline, void delegate() callback) {
		//"""Calls the given callback at the time deadline from the I/O loop."""
		Stdout("IOLoop.add_timeout").newline.flush;
		auto timeout = new _Timeout(deadline, callback);
		this._timeouts ~= timeout;
		this._timeouts = this._timeouts.sort;
		return timeout;
	}

	public void remove_timeout(_Timeout timeout) {
		Stdout("IOLoop.remove_timeout").newline.flush;
		Array!(_Timeout).remove_item(this._timeouts, timeout);
	}

	public void add_callback(void delegate() callback) {
		//"""Calls the given callback on the next I/O loop iteration."""
		Stdout("IOLoop.add_callback").newline.flush;
		this._callbacks ~= callback;
		this._wake();
	}

	public void remove_callback(void delegate() callback) {
		//"""Removes the given callback from the next I/O loop iteration."""
		Stdout("IOLoop.remove_callback").newline.flush;
		Array!(void delegate()).pop_item(this._callbacks, callback);
	}

	public void _wake() {
		Stdout("IOLoop._wake").newline.flush;
		char[] message = "x";
		try {
			fwrite(toStringz(message), message.length, 1, this._waker_writer);
		} catch(IOError e) {

		}
	}

	public void _run_callback(void delegate() callback) {
		Stdout("IOLoop._run_callback").newline.flush;
		try {
			callback();
		} catch(KeyboardInterrupt e) {
			throw(e);
		} catch(SystemExit e) {
			throw(e);
		} catch {
//			logging.error("Exception in callback %r", callback, exc_info=true);
		}
	}

	public void _read_waker(ISelectable.Handle fd, uint events) {
		Stdout("IOLoop._read_waker").newline.flush;
		char* buffer = toStringz(new char[1]);
		try {
			while(true) {
				fread(buffer, 1, 1, this._waker_reader);
			}
		} catch(IOError e) {

		}
		delete buffer;
	}

	public void _set_nonblocking(ISelectable.Handle fd) {
		Stdout("IOLoop._set_nonblocking").newline.flush;
		int GETFL = tango.stdc.posix.fcntl.F_GETFL;
		int SETFL = tango.stdc.posix.fcntl.F_SETFL;
		int O_NONBLOCK = tango.stdc.posix.fcntl.O_NONBLOCK;

		int flags = tango.stdc.posix.fcntl.fcntl(cast(int)fd, GETFL);
		tango.stdc.posix.fcntl.fcntl(cast(int)fd, SETFL, flags | O_NONBLOCK);
	}
}

class _Timeout {
	private float deadline;
	private void delegate() callback;

	//"""An IOLoop timeout, a UNIX timestamp and a callback"""
	public this(float deadline, void delegate() callback) {
		Stdout("_Timeout.__init__").newline.flush;
		this.deadline = deadline;
		this.callback = callback;
	}

	public bool opEquals(_Timeout other) {
		Stdout("_Timeout.opEquals").newline.flush;
		return this.deadline == other.deadline &&
			   this.callback == other.callback;
	}
}

class PeriodicCallback {
	private void delegate() callback = null;
	private float callback_time;
	private IOLoop io_loop = null;
	private bool _running = false;

	//"""Schedules the given callback to be called periodically.
	//
	//The callback is called every callback_time milliseconds.
	//"""
	public this(void delegate() callback, float callback_time, IOLoop io_loop=null) {
		Stdout("PeriodicCallback.__init__").newline.flush;
		this.callback = callback;
		this.callback_time = callback_time;
		if(io_loop)
			this.io_loop = io_loop;
		else
			this.io_loop = IOLoop.instance();
		this._running = true;
	}

	public void start() {
		Stdout("PeriodicCallback.start").newline.flush;
		float timeout = Clock.now.unix.seconds + this.callback_time / 1000.0;
		this.io_loop.add_timeout(timeout, &this._run);
	}

	public void stop() {
		Stdout("PeriodicCallback.stop").newline.flush;
		this._running = false;
	}

	public void _run() {
		Stdout("PeriodicCallback._run").newline.flush;
		if(!this._running) {
			return;
		}
		try {
			this.callback();
		} catch {
//			logging.error("Error in periodic callback", exc_info=true);
		}
		this.start();
	}
}

class _EPoll : BasePoll {
	private ISelectable.Handle[][] fd_sets;

	public this() {
		Stdout("_EPoll.__init__").newline.flush;
//		this.fd_sets = [this.read_fds, this.write_fds, this.error_fds];
		auto selector = new EpollSelector();
		selector.open();
		this._selector = selector;
	}

	public void register(ISelectable.Handle fd, uint events) {
		Stdout("_EPoll.register").newline.flush;
	}

	public void modify(ISelectable.Handle fd, uint events) {
		Stdout("_EPoll.modify").newline.flush;
	}

	public void unregister(ISelectable.Handle fd) {
		Stdout("_EPoll.unregister").newline.flush;
	}

	public EventPair[] poll(Socket sock, float timeout) {
		Stdout("_EPoll.poll").newline.flush;
		EventPair[] retval;
		uint[ISelectable.Handle] events;

		// Wait for any read, hangup, error, or invalid handle events
		this._selector.register(sock, Event.Read | Event.Hangup | Event.Error | Event.InvalidHandle);
		if(this._selector.select(timeout) == 0) {
			return retval;
		}

		// Copy all the fds into a dict
		ISelectable.Handle[] readable, writeable, errors;
		foreach(SelectionKey item; this._selector.selectedSet()) {
			ISelectable.Handle fd = (cast(Socket) item.conduit).fileHandle;
			uint old_event = fd in events ? events[fd] : 0;

			if(item.isReadable()) {
				events[fd] = old_event | IOLoop.READ;
			}
			if(item.isWritable()) {
				events[fd] = old_event | IOLoop.WRITE;
			}
			if(item.isError()) {
				events[fd] = old_event | IOLoop.ERROR;
			}
			if(item.isHangup() || item.isInvalidHandle()) {
				Stdout("FIXME: error, hangup, or invalid handle").flush;
				this._selector.unregister(item.conduit);
			}
		}

		// Convert the dict into event pairs
		foreach(ISelectable.Handle fd, uint event ; events)
			retval ~= new EventPair(fd, event);
		return retval;
	}
}

class _Select : BasePoll {
	private ISelectable.Handle[] read_fds;
	private ISelectable.Handle[] write_fds;
	private ISelectable.Handle[] error_fds;
	private ISelectable.Handle[][] fd_sets;
	private ISelector _selector = null;

	public this() {
		Stdout("_Select.__init__").newline.flush;
		this.fd_sets = [this.read_fds, this.write_fds, this.error_fds];
		auto selector = new SelectSelector();
		selector.open();
		this._selector = selector;
	}

	public void register(ISelectable.Handle fd, uint events) {
		Stdout("_Select.register").newline.flush;
		if(events & IOLoop.READ)
			if(Array!(ISelectable.Handle).contains(this.read_fds, fd) == false)
				this.read_fds ~= fd;
		if(events & IOLoop.WRITE)
			if(Array!(ISelectable.Handle).contains(this.write_fds, fd) == false)
				this.write_fds ~= fd;
		if(events & IOLoop.ERROR)
			if(Array!(ISelectable.Handle).contains(this.error_fds, fd) == false)
				this.error_fds ~= fd;
	}

	public void modify(ISelectable.Handle fd, uint events) {
		Stdout("_Select.modify").newline.flush;
		this.unregister(fd);
		this.register(fd, events);
	}

	public void unregister(ISelectable.Handle fd) {
		Stdout("_Select.unregister").newline.flush;
		Array!(ISelectable.Handle).remove_item(this.read_fds, fd);
		Array!(ISelectable.Handle).remove_item(this.write_fds, fd);
		Array!(ISelectable.Handle).remove_item(this.error_fds, fd);
	}

	public EventPair[] poll(Socket sock, float timeout) {
		Stdout("_Select.poll").newline.flush;
		EventPair[] retval;
		uint[ISelectable.Handle] events;

		// Wait for any read, hangup, error, or invalid handle events
		//this._selector.register(sock, Event.Read | Event.Hangup | Event.Error | Event.InvalidHandle);
		if(this._selector.select(timeout) == 0) {
			return retval;
		}

		// Copy all the fds into a dict
		ISelectable.Handle[] readable, writeable, errors;
		foreach(SelectionKey item; this._selector.selectedSet()) {
			ISelectable.Handle fd = (cast(Socket) item.conduit).fileHandle;
			uint old_event = fd in events ? events[fd] : 0;

			if(item.isReadable()) {
				events[fd] = old_event | IOLoop.READ;
			}
			if(item.isWritable()) {
				events[fd] = old_event | IOLoop.WRITE;
			}
			if(item.isError()) {
				events[fd] = old_event | IOLoop.ERROR;
			}
			if(item.isHangup() || item.isInvalidHandle()) {
				Stdout("FIXME: error, hangup, or invalid handle").flush;
				this._selector.unregister(item.conduit);
			}
		}

		// Convert the dict into event pairs
		foreach(ISelectable.Handle fd, uint event ; events)
			retval ~= new EventPair(fd, event);
		return retval;
	}
}


class BasePoll {
	private ISelector _selector = null;

	public this() {
	}

	public void register(ISelectable.Handle fd, uint events) {
	}

	public void modify(ISelectable.Handle fd, uint events) {
	}

	public void unregister(ISelectable.Handle fd) {
	}

	public EventPair[] poll(Socket sock, float timeout) {
		return null;
	}
}

