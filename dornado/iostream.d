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

//"""A utility class to write to and read from a non-blocking socket."""

module dornado.iostream;

private import tango.io.model.IConduit;
private import tango.net.device.Socket;
private import dornado.ioloop;

public import tango.io.Stdout;


class IOStream {
	private Socket socket;
	private IOLoop io_loop;
	public size_t max_buffer_size;
	private size_t read_chunk_size;
	private string _read_buffer;
	private string _write_buffer;
	private string _read_delimiter;
	private size_t _read_bytes;
	private void delegate(string) _read_callback;
	private void delegate() _write_callback;
	private void delegate() _close_callback;
	private uint _state;

	public this(Socket socket, IOLoop io_loop=null, 
				size_t max_buffer_size=104857600, size_t read_chunk_size=4096) {
		Stdout("IOStream.__init__").newline.flush;
		this.socket = socket;
		this.socket.socket.blocking(false);
		this.io_loop = io_loop ? io_loop : IOLoop.instance();
		this.max_buffer_size = max_buffer_size;
		this.read_chunk_size = read_chunk_size;
		this._read_buffer = "";
		this._write_buffer = "";
		this._read_delimiter = null;
		// FIXME: This may be a problem, because it is null instead of zero in the original python
		this._read_bytes = 0;
		this._read_callback = null;
		this._write_callback = null;
		this._close_callback = null;
		this._state = IOLoop.ERROR;
		this.io_loop.add_handler(
			this.socket.fileHandle, &this._handle_events, this._state);
	}

	public void read_until(string delimiter, void delegate(string) callback) {
		//"""Call callback when we read the given delimiter."""
		Stdout("IOStream.read_until").newline.flush;
		assert(!this._read_callback, "Already reading");
		size_t loc = index(this._read_buffer, delimiter);
		if(loc != this._read_buffer.length) {
			callback(this._consume(loc + delimiter.length));
			return;
		}
		this._check_closed();
		this._read_delimiter = delimiter;
		this._read_callback = callback;
		this._add_io_state(IOLoop.READ);
	}

	public void read_bytes(size_t num_bytes, void delegate(string) callback) {
		//"""Call callback when we read the given number of bytes."""
		Stdout("IOStream.read_bytes").newline.flush;
		assert(!this._read_callback, "Already reading");
		if(this._read_buffer.length >= num_bytes) {
			callback(this._consume(num_bytes));
			return;
		}
		this._check_closed();
		this._read_bytes = num_bytes;
		this._read_callback = callback;
		this._add_io_state(IOLoop.READ);
	}

	public void write(string data, void delegate() callback=null) {
		//"""Write the given data to this stream.
		//
		//If callback is given, we call it when all of the buffered write
		//data has been successfully written to the stream. If there was
		//previously buffered write data and an old write callback, that
		//callback is simply overwritten with this new callback.
		//"""
		Stdout("IOStream.write").newline.flush;
		this._check_closed();
		this._write_buffer ~= data;
		this._add_io_state(IOLoop.WRITE);
		this._write_callback = callback;
	}

	public void set_close_callback(void delegate() callback) {
		//"""Call the given callback when the stream is closed."""
		Stdout("IOStream.set_close_callback").newline.flush;
		this._close_callback = callback;
	}

	public void close() {
		//"""Close this stream."""
		Stdout("IOStream.close").newline.flush;
		if(this.socket !is null) {
			this.io_loop.remove_handler(this.socket.fileHandle);
			this.socket.close();
			this.socket = null;
			if(this._close_callback) this._close_callback();
		}
	}

	public bool reading() {
		//"""Returns true if we are currently reading from the stream."""
		Stdout("IOStream.reading").newline.flush;
		return this._read_callback !is null;
	}

	public bool writing() {
		//"""Returns true if we are currently writing to the stream."""
		Stdout("IOStream.writing").newline.flush;
		return this._write_buffer.length > 0;
	}

	public bool closed() {
		Stdout("IOStream.this").newline.flush;
		return this.socket is null;
	}

	public void _handle_events(ISelectable.Handle fd, uint events) {
		Stdout("IOStream._handle_events").newline.flush;
		if(!this.socket) {
//			logging.warning("Got events for closed stream %d", fd)
			return;
		}
		if(events & IOLoop.READ) {
			this._handle_read();
		}
		if(!this.socket) {
			return;
		}
		if(events & IOLoop.WRITE) {
			this._handle_write();
		}
		if(!this.socket) {
			return;
		}
		if(events & IOLoop.ERROR) {
			this.close();
			return;
		}
		uint state = IOLoop.ERROR;
		if(this._read_delimiter.length > 0 || this._read_bytes) {
			state |= IOLoop.READ;
		}
		if(this._write_buffer.length > 0) {
			state |= IOLoop.WRITE;
		}
		if(state != this._state) {
			this._state = state;
			this.io_loop.update_handler(this.socket.fileHandle, this._state);
		}
	}

	public void _handle_read() {
		Stdout("IOStream._handle_read").newline.flush;
		char[] chunk = new char[this.read_chunk_size];
//		try {
			this.socket.read(chunk);
//		} catch(socket.error e) {
//			if(e[0] in (errno.EWOULDBLOCK, errno.EAGAIN)) {
//				return;
//			} else {
//				logging.warning("Read error on %d: %s",
//								this.socket.fileno(), e)
//				this.close();
//				return;
//			}
//		}
		if(chunk.length == 0) {
			this.close();
			return;
		}
		this._read_buffer ~= chunk;
		if(this._read_buffer.length >= this.max_buffer_size) {
//			logging.error("Reached maximum read buffer size")
			this.close();
			return;
		}
		if(this._read_bytes > 0) {
			if(this._read_buffer.length >= this._read_bytes) {
				size_t num_bytes = this._read_bytes;
				void delegate(string) callback = this._read_callback;
				this._read_callback = null;
				this._read_bytes = 0;
				callback(this._consume(num_bytes));
			}
		} else if(this._read_delimiter.length > 0) {
			size_t loc = index(this._read_buffer, this._read_delimiter);
			if(loc != this._read_buffer.length) {
				void delegate(string) callback = this._read_callback;
				size_t delimiter_len = this._read_delimiter.length;
				this._read_callback = null;
				this._read_delimiter = null;
				callback(this._consume(loc + delimiter_len));
			}
		}
	}

	public void _handle_write() {
		Stdout("IOStream._handle_write").newline.flush;
		while(this._write_buffer.length > 0) {
///			try {
				size_t num_bytes = this.socket.write(this._write_buffer);
				this._write_buffer = this._write_buffer[num_bytes .. length];
//			} catch(socket.error e) {
//				if(e[0] in (errno.EWOULDBLOCK, errno.EAGAIN)) {
//					break;
//				} else {
//					logging.warning("Write error on %d: %s",
//									this.socket.fileno(), e)
///					this.close();
//					return;
//				}
//			}
		}
		if(this._write_buffer.length == 0 && this._write_callback) {
			void delegate() callback = this._write_callback;
			this._write_callback = null;
			callback();
		}
	}

	public string _consume(size_t loc) {
		Stdout("IOStream.string _consume").newline.flush;
		string result = this._read_buffer[0 .. loc-1];
		this._read_buffer = this._read_buffer[loc .. length];
		return result;
	}

	public void _check_closed() {
		Stdout("IOStream._check_closed").newline.flush;
		if(!this.socket) {
			throw new IOError("Stream is closed", 999);
		}
	}

	public void _add_io_state(uint state) {
		Stdout("IOStream._add_io_state").newline.flush;
		if(!this._state & state) {
			this._state = this._state | state;
			this.io_loop.update_handler(this.socket.fileHandle, this._state);
		}
	}
}

