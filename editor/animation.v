import ui
import os
import gg
import gx
import time
import engine

const (
	win_width  = 800
	win_height = 600
)

struct State {
	test     string
	is_error bool
mut:
	sprite_map_path        string
	sprite_map             gg.Image
	animated_sprite        engine.AnimatedSprite
	current_anim_part_rect gg.Rect
	current_anim           &engine.Animation
	frame_sw               time.StopWatch = time.new_stopwatch({})
	zoom_scale             int = 1
	image_offset_x         int
	image_offset_y         int
	mouse_prev_x           f64 = -1
	mouse_prev_y           f64 = -1
	mouse_diff_x           f64
	mouse_diff_y           f64
	//@temp maybe these state exists inside the window
	mouse_down                  bool
	finish_anim_row             &ui.Stack
	creating_anim               bool
	editing_anim                bool
	displaying_finish_anim_btns bool
	mouse_anim_x                f32
	mouse_anim_y                f32
	anim_width                  f32
	anim_height                 f32
}

fn main() {
	if os.args.len != 2 {
		eprintln('Editor takes exacly one argument the image filepath.')
		exit(1)
	} else if !os.exists(os.args[1]) {
		eprintln('${os.args[1]} does not exists')
		exit(1)
	}

	mut app := &State{
		current_anim: &engine.Animation{}
		sprite_map_path: os.args[1]
		finish_anim_row: ui.row({ spacing: 10 }, [
			ui.button(z_index: 1, text: 'X', onclick: btn_cancel_anim_finish_click),
			ui.button(z_index: 1, text: 'Add', onclick: btn_create_anim_finish_click),
		])
	}

	// @todo add CTRL+Q to quit application
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
			ui.canvas(draw_fn: preview_anim_draw),
			// @question : don't know why but widget outside stack are not properly displayed
			app.finish_anim_row,
		]), ui.column({
			spacing: 10
			margin_: 10
		}, [
			ui.row({ spacing: 10 }, [
				ui.button(text: '-', onclick: btn_zoom_minus_click),
				ui.button(text: '+', onclick: btn_zoom_plus_click),
				ui.button(text: 'Create anim', onclick: btn_create_anim_click),
			]),
			// @temp should replace the row above when on animation edition
			ui.row({ spacing: 10 }, [
				ui.button(text: 'Back', onclick: btn_back_click),
				ui.button(text: 'Add frame', onclick: btn_add_frame_click),
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
	hide_finish_anim_btns(mut app.finish_anim_row)
	app.creating_anim = false
	app.editing_anim = true
	app.displaying_finish_anim_btns = false

	app.current_anim = &engine.Animation{}
	app.animated_sprite.animations << app.current_anim
}

fn reset_anim_state(mut app State) {
	app.creating_anim = false
	app.editing_anim = false
	app.displaying_finish_anim_btns = false
	app.anim_width, app.anim_height = 0, 0
	app.mouse_anim_x, app.mouse_anim_y = 0, 0
}

fn btn_cancel_anim_finish_click(mut app State, btn &ui.Button) {
	hide_finish_anim_btns(mut app.finish_anim_row)
	reset_anim_state(mut app)
}

fn btn_back_click(mut app State, btn &ui.Button) {
	hide_finish_anim_btns(mut app.finish_anim_row)
	reset_anim_state(mut app)
}

fn btn_add_frame_click(mut app State, btn &ui.Button) {
	if app.current_anim.frames.len == 0 {
		// Just create a square as the first frame 
		app.current_anim.frames << gg.Rect{app.current_anim_part_rect.x, app.current_anim_part_rect.y, app.current_anim_part_rect.height, app.current_anim_part_rect.height}
	} else {
		// Add a square after the last one
		last_frame := app.current_anim.frames[app.current_anim.frames.len - 1]
		app.current_anim.frames << gg.Rect{last_frame.x + last_frame.width, last_frame.y +
			last_frame.height, app.current_anim_part_rect.height, app.current_anim_part_rect.height}
	}
}

fn window_mouse_down(evt ui.MouseEvent, window &ui.Window) {
	mut app := &State(window.state)
	app.mouse_down = true

	if app.creating_anim && !app.displaying_finish_anim_btns {
		app.mouse_anim_x = f32(evt.x)
		app.mouse_anim_y = f32(evt.y)
	}
}

fn window_mouse_up(evt ui.MouseEvent, window &ui.Window) {
	mut app := &State(window.state)
	app.mouse_down = false
	if app.creating_anim && !app.displaying_finish_anim_btns {
		show_finish_anim_btns(mut app.finish_anim_row, int(evt.x), int(evt.y))
		app.displaying_finish_anim_btns = true
	}
}

// @todo handle mouse move only inside canvas
fn window_mouse_move(evt ui.MouseMoveEvent, window &ui.Window) {
	mut app := &State(window.state)
	if app.mouse_down && !app.editing_anim {
		if app.mouse_prev_x != -1 {
			app.mouse_diff_x, app.mouse_diff_y = evt.x - app.mouse_prev_x, evt.y - app.mouse_prev_y
		}

		if app.creating_anim {
			app.anim_width, app.anim_height = f32(evt.x) - app.mouse_anim_x, f32(evt.y) - app.mouse_anim_y
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
	if app.zoom_scale < 20 && !app.editing_anim {
		app.zoom_scale++
	}
}

fn zoom_out(mut app State) {
	if app.zoom_scale > 1 && !app.editing_anim {
		app.zoom_scale--
	}
}

fn draw_edited_anim(mut ctx gg.Context, mut app State, canvas &ui.Canvas, image_part_width f32, image_part_height f32) {
	// @todo put this in a separate function and store it in the app state
	// @todo check if margin can cause an error in calculus
	rel_x, rel_y := app.mouse_anim_x - canvas.x, app.mouse_anim_y - canvas.y
	img_width_ratio := image_part_width / f32(canvas.width)
	img_height_ratio := image_part_height / f32(canvas.height)
	anim_pos_x := app.image_offset_x + rel_x * img_width_ratio
	anim_pos_y := app.image_offset_y + rel_y * img_height_ratio
	anim_part_width := app.anim_width * img_width_ratio
	anim_part_height := app.anim_height * img_height_ratio

	app.current_anim_part_rect = gg.Rect{anim_pos_x, anim_pos_y, anim_part_width, anim_part_height}

	ctx.draw_image_part(gg.Rect{canvas.x, canvas.y, app.anim_width, app.anim_height},
		app.current_anim_part_rect, app.sprite_map)

	// Now draw anims frame rect
	mut curr_x, mut curr_y := canvas.x, canvas.y
	for frame in app.current_anim.frames {
		ctx.draw_empty_rect(curr_x, curr_y, frame.width / img_width_ratio, frame.height / img_height_ratio,
			gx.gray)
		curr_x += int(frame.width / img_width_ratio)
	}
}

fn draw_zoomed_image(mut ctx gg.Context, mut app State, canvas &ui.Canvas) {
	// Fit image inside the canvas
	// @todo doesn't work on some cases like is_image_larger false and canvas width < image width
	is_image_larger := app.sprite_map.width > app.sprite_map.height
	mut image_width, mut image_height := app.sprite_map.width, app.sprite_map.height
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
	width_ratio := f32(canvas.width) / f32(image_width)
	height_ratio := f32(canvas.height) / f32(image_height)

	// Calculate which part to display and crop image to canvas
	mut image_part_width, mut image_part_height := app.sprite_map.width, app.sprite_map.height
	if image_width > canvas.width {
		image_part_width = int(image_part_width * width_ratio)
		image_width = canvas.width
	}

	if image_height > canvas.height {
		image_part_height = int(image_part_height * height_ratio)
		image_height = canvas.height
	}

	// Calculate offset (we can grab image on mouse move + down)
	// Only move image when it is not entirely display
	offset_padding := 10
	new_offset_x := app.image_offset_x - int(app.mouse_diff_x)
	if !app.creating_anim && app.mouse_diff_x != 0 && app.sprite_map.width > canvas.width
		&& new_offset_x >= -offset_padding
		&& new_offset_x + image_part_width < app.sprite_map.width + offset_padding {
		app.image_offset_x = new_offset_x
	}

	new_offset_y := app.image_offset_y - int(app.mouse_diff_y)
	if !app.creating_anim && app.mouse_diff_y != 0 && app.sprite_map.height > canvas.height
		&& new_offset_y >= -offset_padding
		&& new_offset_y + image_part_height < app.sprite_map.height + offset_padding {
		app.image_offset_y = new_offset_y
	}

	if app.editing_anim {
		draw_edited_anim(mut ctx, mut app, canvas, f32(image_part_width), f32(image_part_height))
	} else {
		ctx.draw_image_part(gg.Rect{canvas.x, canvas.y, image_width, image_height}, gg.Rect{app.image_offset_x, app.image_offset_y, image_part_width, image_part_height},
			app.sprite_map)
	}
}

//@temp there is no hide mecanism in ui for now
fn hide_finish_anim_btns(mut row ui.Stack) {
	for mut btn in row.get_children() {
		if btn is ui.Button {
			btn.x = -100
			btn.y = -100
		}
	}
}

//@temp : hacky way to move buttons inside a row
fn show_finish_anim_btns(mut row ui.Stack, pos_x int, pos_y int) {
	for ind, mut btn in row.get_children() {
		if btn is ui.Button {
			btn.x = pos_x - 100 / (ind + 1)
			btn.y = pos_y + 10
		}
	}
	/*
	mut cancel_btn := row.get_children()[0]
    mut add_btn := row.get_children()[1]

    if cancel_btn is ui.Button {
        cancel_btn.x = pos_x - (cancel_btn.width + add_btn.width + 10)
        cancel_btn.y = pos_y + 10
    }

    if add_btn is ui.Button {
        add_btn.x = pos_x - add_btn.width
        add_btn.y = pos_y + 10
    }
	*/
}

fn canvas_draw(mut ctx gg.Context, mut app State, canvas &ui.Canvas) {
	// @temp kind of hacky need to find a way to use ctx before
	if !app.sprite_map.ok {
		println('Load img')
		app.sprite_map = ctx.create_image(app.sprite_map_path)
		app.animated_sprite.img = app.sprite_map
		// @temp don't know why it can be done right after window creation
		hide_finish_anim_btns(mut app.finish_anim_row)
	}

	draw_zoomed_image(mut ctx, mut app, canvas)

	if app.creating_anim {
		// @todo draw two rectangle to have a "bolder" rect
		// @ bug rect is displayed when clicking on finish ("frame" bug because mouse down is called before button click)
		ctx.draw_empty_rect(f32(app.mouse_anim_x), f32(app.mouse_anim_y), app.anim_width,
			app.anim_height, gx.gray)
	}
}

fn preview_anim_draw(mut ctx gg.Context, mut app State, canvas &ui.Canvas) {
	if app.current_anim.frames.len > 0 {
		delta_t := f64(app.frame_sw.elapsed().microseconds()) / 1000.0
		app.frame_sw.restart()

		frame_rect := app.current_anim.get_current_frame_rect(delta_t)

		// @bug animation is not working properly, maybe frame are not well created ?
		ctx.draw_image_part(gg.Rect{canvas.x, canvas.y, frame_rect.width, frame_rect.height},
			frame_rect, app.sprite_map)
	}
}
