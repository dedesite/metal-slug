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
	zoom_scale          int = 1
	image_offset_x      int
	image_offset_y      int
	mouse_prev_x        f64 = -1
	mouse_prev_y        f64 = -1
	mouse_diff_x        f64
	mouse_diff_y        f64
	//@temp maybe those state exists inside the window
	mouse_down bool
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
		on_mouse_move: window_mouse_move
		on_mouse_down: window_mouse_down
		on_mouse_up: window_mouse_up
		on_scroll: window_scroll
	}, [
		ui.row({
			spacing: 10
			widths: [0.2, 0.8]
			heights: ui.stretch
		}, [ui.column({
			spacing: 10
			margin_: 10
		}, [
			ui.button(text: '+', onclick: btn_add_anim_click),
		]), ui.column({
			spacing: 10
			margin_: 10
		}, [
			ui.row({ spacing: 10 }, [
				ui.button(text: '-', onclick: btn_zoom_minus_click),
				ui.button(text: '+', onclick: btn_zoom_plus_click),
			]),
			ui.canvas(
				draw_fn: canvas_draw
			),
		])]),
	])
	ui.run(window)
}

fn btn_zoom_minus_click(mut app State, x voidptr) {
	zoom_out(mut app)
}

fn btn_zoom_plus_click(mut app State, x voidptr) {
	zoom_in(mut app)
}

fn btn_add_anim_click(mut app State, btn &ui.Button) {
	mut children := btn.parent.get_children()
	children << ui.button(text: '+')
}

fn window_mouse_down(evt ui.MouseEvent, window &ui.Window) {
	mut app := &State(window.state)
	app.mouse_down = true
}

fn window_mouse_up(evt ui.MouseEvent, window &ui.Window) {
	mut app := &State(window.state)
	app.mouse_down = false
}

fn window_mouse_move(evt ui.MouseMoveEvent, window &ui.Window) {
	mut app := &State(window.state)
	if app.mouse_down {
		println('go $app.mouse_diff_x $app.mouse_diff_y')
		if app.mouse_prev_x != -1 {
			app.mouse_diff_x, app.mouse_diff_y = evt.x - app.mouse_prev_x, evt.y - app.mouse_prev_y
		}
	} else {
		app.mouse_diff_x, app.mouse_diff_y = 0, 0
	}
	app.mouse_prev_x = evt.x
	app.mouse_prev_y = evt.y
}

fn window_scroll(evt ui.ScrollEvent, mut window ui.Window) {
	if evt.y > 0 {
		zoom_in(mut window.state)
	} else {
		zoom_out(mut window.state)
	}
}

fn zoom_in(mut app State) {
	if app.zoom_scale < 20 {
		app.zoom_scale++
	}
}

fn zoom_out(mut app State) {
	if app.zoom_scale > 1 {
		app.zoom_scale--
	}
}

fn canvas_draw(mut ctx gg.Context, mut app State, canvas &ui.Canvas) {
	// @temp kind of hacky need to find a way to use ctx before
	if !app.current_sprite.ok {
		println('Load img')
		app.current_sprite = ctx.create_image(app.current_sprite_path)
	}

	if app.image_offset_x == 0 {
		app.image_offset_x, app.image_offset_y = canvas.x, canvas.y
	}

	image_larger := app.current_sprite.width > app.current_sprite.height
	mut image_width, mut image_height := app.current_sprite.width, app.current_sprite.height
	if image_larger {
		image_height = int(image_height * f32(canvas.width) / f32(image_width))
		image_width = canvas.width
	} else {
		image_width = int(image_width * f32(canvas.height) / f32(image_height))
		image_height = canvas.height
	}

	image_width *= int(app.zoom_scale)
	image_height *= int(app.zoom_scale)

	// Only move image when it is not entirely display
	// @temp not fully functionnal right now
	if app.mouse_diff_x != 0 && image_width > canvas.width
		&& app.image_offset_x + app.mouse_diff_x >= canvas.x {
		app.image_offset_x += int(app.mouse_diff_x)
	}

	if app.mouse_diff_y != 0 && image_height > canvas.height
		&& app.image_offset_y + app.mouse_diff_y >= canvas.y {
		app.image_offset_y += int(app.mouse_diff_y)
	}
	ctx.draw_image(app.image_offset_x, app.image_offset_y, image_width, image_height,
		app.current_sprite)
}
