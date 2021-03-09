import gg
import gx

struct Game {
mut:
	gg &gg.Context = 0
	img gg.Image
}

fn on_frame(mut game Game) {
	game.gg.begin()

	game.gg.draw_image(0, 0, 100, 100, game.img)

	game.gg.end()
}

fn on_event(e &gg.Event, mut game Game) {
}

fn main() {
	mut game := &Game{}
	game.gg = gg.new_context(
		width: 640
		height: 480
		window_title: 'Metal Vlug!'
		bg_color: gx.black
		use_ortho: true
		user_data: game
		frame_fn: on_frame
		event_fn: on_event
	)

	//game.img = game.gg.create_image('./sprites/Neo Geo NGCD - Metal Slug - Marco Rossi.gif')
	game.img = game.gg.create_image_with_size('./sprites/Neo Geo NGCD - Metal Slug - Marco Rossi.gif', 100, 100)
	game.gg.run()
}
