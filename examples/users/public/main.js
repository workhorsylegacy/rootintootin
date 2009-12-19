
function post_href(method) {
	if (!confirm('Are you sure?'))
		return;

	var form = document.createElement('form');
	form.style.display = 'none';
	this.parentNode.appendChild(form);
	form.method = 'POST';
	form.action = this.href;

	var input = document.createElement('input');
	input.setAttribute('type', 'hidden');
	input.setAttribute('name', '_method');
	input.setAttribute('value', method);
	form.appendChild(input);

	form.submit();
}
