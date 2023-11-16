mod gui;
mod util;

use crate::gui::gui_loop;
use crate::util::load_nodes;
use std::net::TcpStream;
use std::io::{BufRead, Read, BufReader, Write};

fn main() {
    let nodes = load_nodes().expect("failed to load nodes.txt");

    let mut s = TcpStream::connect("127.0.0.1:1337").expect("");
    let mut r = BufReader::new(s.try_clone().expect(""));
    _ = write!(&mut s, "Decho aaa\0");
    let mut lenb = Vec::<u8>::new();
    _ = r.read_until(0, &mut lenb);
    let len: usize = String::from_utf8(lenb[0..lenb.len()-1].to_vec()).expect("").parse().expect("");
    let mut res = Vec::<u8>::new();
    _ = r.read_to_end(&mut res);
    println!("{:?}", res);

    // gui_loop();
}
