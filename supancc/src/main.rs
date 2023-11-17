mod gui;
mod util;

use crate::gui::gui_loop;
use crate::util::{load_nodes, load_image};
use std::net::TcpStream;
use std::io::{BufRead, Read, BufReader, Write};

fn main() {
    let _nodes = load_nodes().expect("failed to load nodes.txt");
    let r = render();
    gui_loop(load_image(r).expect("render failed"));
}


fn render() -> Vec<u8> {
    let mut s = TcpStream::connect("192.168.0.5:31337").expect("failed to connect");
    let mut r = BufReader::new(s.try_clone().expect(""));
    _ = write!(&mut s, "Dmenger 600 620 600 620\0");
    let mut _lenb = Vec::<u8>::new();
    r.read_until(0, &mut _lenb).expect("failed to read header");
    let mut res = Vec::<u8>::new();
    _ = r.read_to_end(&mut res).expect("failed to read body");
    res
}
