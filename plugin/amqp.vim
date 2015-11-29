" amqp.vim - A simple AMQP wrapper Vim
" Maintainer:   Andreas Müller <http://0x7.ch>
" Version:      0.1

if exists('g:loaded_amqp') || &cp
  finish
endif
let g:loaded_amqp = 1

" settings
if !exists('g:amqp_mappings')
	let g:amqp_mappings                 = 0
endif
if !exists('g:amqp_host')
	let g:amqp_host                     = 'localhost'
endif
if !exists('g:amqp_port')
	let g:amqp_port                     = '5672'
endif
if !exists('g:amqp_vhost')
	let g:amqp_vhost                    = ''
endif
if !exists('g:amqp_user')
	let g:amqp_user                     = 'guest'
endif
if !exists('g:amqp_password')
	let g:amqp_password                 = 'guest'
endif
if !exists('g:amqp_default_exchange')
	let g:amqp_default_exchange         = ''
endif
if !exists('g:amqp_default_queue')
	let g:amqp_default_queue            = ''
endif
if !exists('g:amqp_default_filetype')
	let g:amqp_default_filetype         = ''
endif
if !exists('g:amqp_filter')
	let g:amqp_filter                   = ''
endif

" AMQP URL
if !exists('g:amqp_url')
	let g:amqp_url = 'amqp://'.g:amqp_user.':'.g:amqp_password.'@'.g:amqp_host.':'.g:amqp_port.'/'.g:amqp_vhost
endif

" mappings
if g:amqp_mappings
	nnoremap <leader>ag :AMQPGet<CR>
	nnoremap <leader>ap :1,$AMQPPublish<CR>
	vnoremap <leader>ap :AMQPPublish<CR>
endif

" commands
command! -nargs=* AMQPGet call s:AMQPGet(<f-args>)
command! -range -nargs=* AMQPPublish <line1>,<line2>call s:AMQPPublish(<f-args>)

function! s:AMQPGet(...)
	" variables - buffer variables take precendence over global variables
	for l:varname in ['default_queue', 'default_filetype', 'filter']
		if exists('b:amqp_'.l:varname)
			execute 'let l:'.l:varname.' = b:amqp_'.l:varname
		else
			execute 'let l:'.l:varname.' = g:amqp_'.l:varname
		endif
	endfor

	" arguments
	if (len(a:000) > 0)
		let l:queue = a:0
	else
		let l:queue = l:default_queue
	endif

	" request
	let l:cmd = 'amqp-get --url='.g:amqp_url.' --queue='.l:queue
	" echo l:cmd
	call s:ScratchBufferCommand(l:default_filetype, l:cmd)
	" apply filter if given
	if exists("l:filter") && strlen(l:filter) > 0
		try | execute "%!".l:filter | catch | endtry
	endif
endfunction

function! s:AMQPPublish(...) range
	" variables - buffer variables take precendence over global variables
	for l:varname in ['default_exchange']
		if exists('b:amqp_'.l:varname)
			execute 'let l:'.l:varname.' = b:amqp_'.l:varname
		else
			execute 'let l:'.l:varname.' = g:amqp_'.l:varname
		endif
	endfor

	" arguments
	if (len(a:000) > 0)
		let l:exchange = a:0
	else
		let l:exchange = l:default_exchange
	endif

	" request
	let l:cmd = 'amqp-publish --url='.g:amqp_url.' --exchange='.l:exchange
	execute a:firstline.','.a:lastline.'w !'.l:cmd
endfunction

function! s:ScratchBuffer(filetype)
	new
	setlocal buftype=nofile
	setlocal bufhidden=hide
	setlocal noswapfile
	setlocal nobuflisted
	if len(a:filetype) > 0
		execute 'setlocal filetype='.a:filetype
	endif
endfunction

function! s:ScratchBufferCommand(filetype, command)
	call s:ScratchBuffer(a:filetype)

	execute '0r!'.a:command
	1
endfunction
