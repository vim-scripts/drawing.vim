" drawing.vim
"
" Some ascii drawing function
" 
" Auteur: Sylvain VIART (molo@multimania.com)
" Date : dimanche 04 mars 2001, 15:12:54 Est
"

" spacer
vmap \s :<c-u>call Spacer(line("'<"), line("'>"))<cr>

" fill end of line with space until textwidth.
func! Spacer(debut, fin)
	let l = a:debut
	let max = &textwidth
	while l <= a:fin
		let content = getline(l)
		let long = strlen(content)
		let i = long
		let space = ''
		while i <= max
			let space = space . ' '
			let i = i + 1
		endw
		call setline(l, content.space)
		let l = l + 1
	endw
endf

" holer, create a space-filled hole under the cursor
nmap \h :call Holer()<cr>
func! Holer()
	let nb = input("how many line under the cursor ? ")
	exe "norm ".nb."o\e"
	let fin = line('.')
	call Spacer(fin-nb+1, fin)
	exe "norm ".(nb-1)."k"
endf

vmap \b :<c-u>call Call_corner('Box')<cr>

func! Box(x0, y0, x1, y1)
	" loop each line
	let l = a:y0
	while l <= a:y1
		let c = a:x0
		while c <= a:x1
			if l == a:y0 || l == a:y1
				let remp = '-'
				if c == a:x0 || c == a:x1
					let remp = '+'
				endif
			else
				let remp = '|'
				if c != a:x0 && c != a:x1
					let remp = '.'
				endif
			endif

			if remp != '.'
				call SetCharAt(remp, c, l)
			endif
			let c  = c + 1
		endw
		let l = l + 1
	endw
endf

" set the character at the specified position (must exist)
func! SetCharAt(char, x, y)
	let content = getline(a:y)
	let long = strlen(content)
	let deb = strpart(content, 0, a:x - 1)
	let fin = strpart(content, a:x, long)
	call setline(a:y, deb.a:char.fin)
endf

vmap \l :<c-u>call Call_corner('DrawLine')<CR>
" Bresenham linedrawing algorithm
" taken from :
" http://www.graphics.lcs.mit.edu/~mcmillan/comp136/Lecture6/Lines.html
func! DrawLine(x0, y0, x1, y1)
	let x0 = a:x0
	let y0 = a:y0

	let dy = a:y1 - a:y0
	let dx = a:x1 - a:x0

	if dy < 0
		let dy = -dy
		let stepy = -1
	else
		let stepy = 1
	endif

	if dx < 0
		let dx = -dx
		let stepx = -1
	else
		let stepx = 1
	endif

	let dy = 2*dy
	let dx = 2*dx

	if dx > dy
		" move under x
		let char = '_'
		call SetCharAt(char, a:x0, a:y0)
		let fraction = dy - (dx / 2)  " same as 2*dy - dx
		while x0 != a:x1
			let char = '_'
			if fraction >= 0
				if stepx > 0
					let char = '\'
				else
					let char = '/'
				endif
				let y0 = y0 + stepy
				let fraction = fraction - dx    " same as fraction -= 2*dx
			endif
			let x0 = x0 + stepx
			let fraction = fraction + dy	" same as fraction = fraction - 2*dy
			call SetCharAt(char, x0, y0)
		endw
	else
		" move under y
		let char = '|'
		call SetCharAt(char, a:x0, a:y0)
		let fraction = dx - (dy / 2)
		while y0 != a:y1 
			let char = '|'
			if fraction >= 0
				if stepy > 0 || stepx < 0
					let char = '\'
				else
					let char = '/'
				endif
				let x0 = x0 + stepx
				let fraction = fraction - dy
			endif
			let y0 = y0 + stepy
			let fraction = fraction + dx
			call SetCharAt(char, x0, y0)
		endw
	endif
endf

vmap \a :<c-u>call Call_corner('Arrow')<CR>
func! Arrow(x0, y0, x1, y1)

	call DrawLine(a:x0, a:y0, a:x1, a:y1)

	let dy = a:y1 - a:y0
	let dx = a:x1 - a:x0
	if Abs(dx) > Abs(dy)
		" move x
		if dx > 0
			call SetCharAt('>', a:x1, a:y1)
		else
			call SetCharAt('<', a:x1, a:y1)
		endif
	else
		" move y
		if dx > 0
			call SetCharAt('v', a:x1, a:y1)
		else
			call SetCharAt('^', a:x1, a:y1)
		endif
	endif

endf

func! Abs(val)
	if a:val < 0 
		return - a:val
	else
		return a:val
	endif
endf

" mouse mappings

" start visual-block with s-LastMouse
nnoremap <s-leftmouse> <leftmouse><c-v>

" Read visual drag mapping
" The visual start point is saved in b:x_drag and b:y_drag
" The event <LeftDrag> is send when the window is resized, we must disable
" this feature
noremap <LeftDrag> <LeftDrag>:<c-u>call Drag_start()<cr>
func! Drag_start()
	unmap <LeftDrag>
	let b:x_drag = col('.')
	let b:y_drag = line('.')
	let b:winheight = winheight(0)
	noremap <LeftRelease> <LeftRelease>:<c-u>call Drag_end()<cr>
endf!

func! Drag_end()
	unmap <LeftRelease>
	noremap <LeftDrag> <LeftDrag>:<c-u>call Drag_start()<cr>
	if b:winheight == winheight(0)
		norm gv
	endif
endf

" call the specified function with the corner position of the current visual
" selection.
func! Call_corner(func_name)
	let xdep = b:x_drag
	let ydep = b:y_drag

	let x0 = col("'<")
	let y0 = line("'<")
	let x1 = col("'>")
	let y1 = line("'>")
	
	if x1 == xdep && y1 ==ydep
		let x1 = x0
		let y1 = y0
		let x0 = xdep
		let y0 = ydep
	endif

	echo xdep.','.ydep.','.x0.','.y0.','.x1.','.y1
	exe "call ".a:func_name."(".x0.','.y0.','.x1.','.y1.")"
endf
" vim: set ts=3 sw=3:
