import ui
import os
import gg
import gx

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
	mouse_down    bool
	creating_anim bool
	mouse_anim_x  f64
	mouse_anim_y  f64
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
		// @todo find a way to move it where we want (absolute position, maybe with offset_x, offset_y ?)
		ui.button(text: 'Add', onclick: btn_create_anim_finish_click),
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
				ui.button(text: 'Create anim', onclick: btn_create_anim_click),
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

fn btn_create_anim_click(mut app State, btn &ui.Button) {
	app.creating_anim = true
}

fn btn_create_anim_finish_click(mut app State, btn &ui.Button) {
}

fn window_mouse_down(evt ui.MouseEvent, window &ui.Window) {
	mut app := &State(window.state)
	app.mouse_down = true

	if app.creating_anim {
		app.mouse_anim_x = evt.x
		app.mouse_anim_y = evt.y
	}

	btn := window.get_children()[0]
	println('$btn.text')
}

fn window_mouse_up(evt ui.MouseEvent, window &ui.Window) {
	mut app := &State(window.state)
	app.mouse_down = false
}

// @todo handle mouse move only inside canvas
fn window_mouse_move(evt ui.MouseMoveEvent, window &ui.Window) {
	mut app := &State(window.state)
	if app.mouse_down {
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

fn draw_zoomed_image(mut ctx gg.Context, mut app State, canvas &ui.Canvas) {
	// Fit image inside the canvas
	// @todo doesn't work on some cases like is_image_larger false and canvas width < image width
	is_image_larger := app.current_sprite.width > app.current_sprite.height
	mut image_width, mut image_height := app.current_sprite.width, app.current_sprite.height
	if is_image_larger {
		image_height = int(image_height * f32(canvas.width) / f32(image_width))
		image_width = canvas.width
	} else {
		image_width = int(image_width * f32(canvas.height) / f32(image_height))
		image_height = canvas.height
	}

	// Applying zoom
	// @todo add a way to zoom at mouse position
	image_width *= int(app.zoom_scale)
	image_height *= int(app.zoom_scale)

	// Calculate which part to display and crop image to canvas
	mut image_part_width, mut image_part_height := app.current_sprite.width, app.current_sprite.height
	if image_width > canvas.width {
		image_part_width = int(image_part_width * f32(canvas.width) / f32(image_width))
		image_width = canvas.width
	}

	if image_height > canvas.height {
		image_part_height = int(image_part_height * f32(canvas.height) / f32(image_height))
		image_height = canvas.height
	}

	// Calculate offset (we can grab image on mouse move + down)
	// Only move image when it is not entirely display
	offset_padding := 10
	new_offset_x := app.image_offset_x - int(app.mouse_diff_x)
	if !app.creating_anim && app.mouse_diff_x != 0 && app.current_sprite.width > canvas.width
		&& new_offset_x >= -offset_padding
		&& new_offset_x + image_part_width < app.current_sprite.width + offset_padding {
		app.image_offset_x = new_offset_x
	}

	new_offset_y := app.image_offset_y - int(app.mouse_diff_y)
	if !app.creating_anim && app.mouse_diff_y != 0 && app.current_sprite.height > canvas.height
		&& new_offset_y >= -offset_padding
		&& new_offset_y + image_part_height < app.current_sprite.height + offset_padding {
		app.image_offset_y = new_offset_y
	}

	ctx.draw_image_part(gg.Rect{canvas.x, canvas.y, image_width, image_height}, gg.Rect{app.image_offset_x, app.image_offset_y, image_part_width, image_part_height},
		app.current_sprite)
}

fn canvas_draw(mut ctx gg.Context, mut app State, canvas &ui.Canvas) {
	// @temp kind of hacky need to find a way to use ctx before
	if !app.current_sprite.ok {
		println('Load img')
		app.current_sprite = ctx.create_image(app.current_sprite_path)
	}

	draw_zoomed_image(mut ctx, mut app, canvas)

	if app.creating_anim && app.mouse_down {
		anim_width, anim_height := app.mouse_prev_x - app.mouse_anim_x, app.mouse_prev_y - app.mouse_anim_y
		// @todo draw two rectangle to have a "bolder" rect
		// @todo find a way to draw a button for validating anim creation
		ctx.draw_rect(f32(app.mouse_anim_x), f32(app.mouse_anim_y), f32(anim_width), f32(anim_height),
			gx.gray)
	}
}
