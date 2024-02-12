mod gui;
mod util;

use crate::gui::gui_loop;
use crate::util::{load_image, load_nodes};
use std::io::{BufRead, BufReader, Read, Write};
use std::net::TcpStream;

fn main() {
    let _nodes = load_nodes().expect("failed to load nodes.txt");
    let r = render();
    gui_loop(load_image(r).expect("render failed"));
}

fn render() -> Vec<u8> {
    let mut s = TcpStream::connect("127.0.0.1:31337").expect("failed to connect");
    let mut r = BufReader::new(s.try_clone().expect(""));
    _ = write!(&mut s, "Dmenger 600 600 0 600 0 600\0");
    let mut lenb = vec![];
    while lenb.is_empty() {
        r.read_until(0, &mut lenb).expect("failed to read header");
        if lenb == vec![0] {
            lenb = vec![];
        }
    }
    let mut res = Vec::<u8>::new();
    _ = r.read_to_end(&mut res).expect("failed to read body");
    res
}
