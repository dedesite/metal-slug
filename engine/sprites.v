module engine

import gg
import time

/*
pub struct Rect {
	x f32
	y f32
	width f32
	height f32
}
*/

pub struct Engine {
mut:
	sprites  []AnimatedSprite
	frame_sw time.StopWatch = time.new_stopwatch({})
pub mut:
	ctx &gg.Context
}

struct Sprite {
mut:
	img  gg.Image
	rect gg.Rect
}

struct Animation {
	frames []gg.Rect
mut:
	current_frame_index int
	current_frame_ms    f64 = 0.0
}

struct AnimatedSprite {
	Sprite
	fps        int = 24
	animations []Animation
mut:
	current_animation_index int
}

fn (mut s AnimatedSprite) animate(ctx gg.Context, delta_t f64) {
	if s.animations.len == 0 {
		ctx.draw_image_part(s.rect, gg.Rect{0, 0, 50, 50}, s.img)
	} else {
		mut current_animation := &s.animations[s.current_animation_index]
		current_animation.current_frame_ms += delta_t
		if current_animation.current_frame_ms > 1000 / s.fps {
			println('New frame ${current_animation.current_frame_ms}')
			current_animation.current_frame_ms = 0
			if current_animation.current_frame_index < current_animation.frames.len - 1 {
				current_animation.current_frame_index++
			} else {
				current_animation.current_frame_index = 0
			}
		}
		current_frame_rect := current_animation.frames[current_animation.current_frame_index]
		ctx.draw_image_part(s.rect, current_frame_rect, s.img)
	}
}

pub fn (mut e Engine) create_animated_sprite(file string) {
	mut s := AnimatedSprite{
		animations: [
			{
				frames: [
					gg.Rect{0, 0, 50, 50},
					gg.Rect{32, 0, 50, 50},
					gg.Rect{65, 0, 50, 50},
					gg.Rect{97, 0, 50, 50},
				]
			},
		]
	}
	s.img = e.ctx.create_image(file)
	s.rect = gg.Rect{0, 0, 100, 100}
	// s.animations << 
	e.sprites << s
}

pub fn (mut e Engine) update_sprites() {
	e.ctx.begin()

	delta_t := f64(e.frame_sw.elapsed().microseconds()) / 100.0

	for mut sprite in e.sprites {
		sprite.animate(e.ctx, delta_t)
	}

	e.ctx.end()
	e.frame_sw.restart()
}

// Not working for now because we can't access image_cache...
/*
pub fn (e &Engine) draw_image_part(img_rect Rect, part_rect Rect, img_ &gg.Image) {
	if img_.id >= ctx.image_cache.len {
		eprintln('gg: draw_image() bad img id $img_.id (img cache len = $ctx.image_cache.len)')
		return
	}
	img := ctx.image_cache[img_.id] // fetch the image from cache


	if !img.simg_ok {
		//return
	}
	u0 := part_rect.x / img.width
	v0 := part_rect.y / img.height
	u1 := (part_rect.x + part_rect.width) / img.width
	v1 := (part_rect.y + part_rect.height) / img.height
	//println("u0: $u0 v0: $v0 u1: $u1 v1: $v1 width: ${img.width} height: ${img.height}")
	x0 := img_rect.x * e.ctx.scale
	y0 := img_rect.y * e.ctx.scale
	x1 := (img_rect.x + img_rect.width) * e.ctx.scale
	mut y1 := (img_rect.y + img_rect.height) * e.ctx.scale
	if img_rect.height == 0 {
		scale := f32(img.width) / f32(img_rect.width)
		y1 = f32(img_rect.y + int(f32(img.height) / scale)) * e.ctx.scale
	}
	//
	sgl.load_pipeline(e.ctx.timage_pip)
	sgl.enable_texture()
	sgl.texture(img.simg)
	sgl.begin_quads()
	sgl.c4b(255, 255, 255, 255)
	sgl.v2f_t2f(x0, y0, u0, v0)
	sgl.v2f_t2f(x1, y0, u1, v0)
	sgl.v2f_t2f(x1, y1, u1, v1)
	sgl.v2f_t2f(x0, y1, u0, v1)
	sgl.end()
	sgl.disable_texture()
}
*/
