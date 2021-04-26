struct Toto {
	ok bool
}

struct RefHolder {
	t &Toto
}

fn main() {
	r := create_ref_holder()
	println(r)
}

fn create_ref_holder() RefHolder {
	// Allocated on the stack
	t := Toto{}
	r := RefHolder{
		// After this function, this reference should point to nothing ?
		t: &t
	}

	return r
}