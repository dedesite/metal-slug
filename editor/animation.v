import ui
import os
import gg

const (
	win_width  = 800
	win_height = 600
)

struct State {
	test     string
	is_error bool
mut:
	current_sprite_path string
	current_sprite      gg.Image
	zoom_scale          f32 = 1.
}

fn main() {
	if os.args.len != 2 {
		eprintln('Editor takes exacly one argument the image filepath.')
		exit(1)
	} else if !os.exists(os.args[1]) {
		eprintln('${os.args[1]} does not exists')
		exit(1)
	}

	mut app := &State{}
	app.current_sprite_path = os.args[1]

	window := ui.window({
		width: win_width
		height: win_height
		state: app
		title: 'Sprite Animation Editor'
		mode: .resizable
		// bg_color: gx.light_blue
	}, [
		ui.row({
			spacing: 10
			widths: ui.stretch
			heights: ui.stretch
		}, [
			ui.textbox(
				max_len: 20
				placeholder: 'First name'
				text: &app.test
				is_error: &app.is_error
				is_focused: true
			),
			ui.column({
				spacing: 10
			}, [
				ui.row({ spacing: 10 }, [
					ui.button(text: '-', onclick: btn_zoom_minus_click),
					ui.button(text: '+', onclick: btn_zoom_plus_click),
				]),
				ui.canvas(
					draw_fn: canvas_draw
				),
			]),
		]),
	])
	ui.run(window)
}

fn btn_zoom_minus_click(mut app State, x voidptr) {
	app.zoom_scale--
}

fn btn_zoom_plus_click(mut app State, x voidptr) {
	app.zoom_scale++
}

fn canvas_draw(mut ctx gg.Context, mut app State, canvas &ui.Canvas) {
	// @temp kind of hacky need to find a way to use ctx before
	if !app.current_sprite.ok {
		println('Load img')
		app.current_sprite = ctx.create_image(app.current_sprite_path)
	}

	x_offset, y_offset := canvas.x, canvas.y
	// println(ctx.scale)
	// ctx.scale = app.zoom_scale
	ctx.draw_image(x_offset, y_offset, win_width - x_offset, win_height - y_offset, app.current_sprite)
}
