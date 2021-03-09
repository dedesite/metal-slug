import gg
import gx
import engine

struct Game {
mut:
	e engine.Engine
}

fn on_frame(mut game Game) {
	game.e.update_sprites()
}

fn on_event(e &gg.Event, mut game Game) {
}

fn main() {
	mut game := &Game{}
	game.e.ctx = gg.new_context(
		width: 640
		height: 480
		window_title: 'Metal Vlug!'
		bg_color: gx.black
		use_ortho: true
		user_data: game
		frame_fn: on_frame
		event_fn: on_event
	)

	game.e.create_animated_sprite('./sprites/Neo Geo NGCD - Metal Slug - Marco Rossi.gif')
	game.e.ctx.run()
}
