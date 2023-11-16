/*
 * YE WHO ENTRE HERE, WELCOME TO THE SPAGHETTI MESS, NOT PROUD OF THIS
 * ONE BUT CAN'T BE BOTHERED...
 *                                           -- Evert
 */

use std::fs::File;
use std::io::{BufRead, BufReader, Write, Error};
use std::thread::available_parallelism;
use std::net::{TcpStream, TcpListener, Shutdown};
use std::process::Command;
use std::thread;

fn main() {
    let apps = load_apps().expect("failed to load apps.txt");
    let listener = TcpListener::bind("127.0.0.1:1337").unwrap();

    for stream in listener.incoming() {
        let mut stream = stream.unwrap();
        let apps = apps.clone();
        thread::spawn(move || {
            handle_connection(&mut stream, &apps);
        });
    }
}

fn handle_connection(stream: &mut TcpStream, apps: &Vec<String>) {
    let mut req = Vec::<u8>::new();
    if let Ok(cstream) = stream.try_clone() {
        if let Ok(_) = BufReader::new(cstream).read_until(0, &mut req) {
            if req.len() == 0 {
                return;
            }
            match req[0].into() {
                'D' => {
                    if req.len() > 1+1 {
                        if let Ok(str) = String::from_utf8(req[1..req.len()-1].to_vec()) {
                            let mut args = str.split_whitespace();
                            if let Some(app) = args.next() {
                                run_app(stream, app.to_string(), args.map(|s| s.to_string()).collect(), apps);
                            }
                        }
                    }
                },
                'I' => info(stream),
                _ => (),
            }
        }
    }
    _ = stream.flush();
    _ = stream.shutdown(Shutdown::Both);
}

fn load_apps() -> Result<Vec<String>, Error> {
    BufReader::new(File::open("apps.txt")?).lines().collect()
}

fn run_app<W: Write>(out: &mut W, app: String, args: Vec<String>, apps: &Vec<String>) {
    // This line does all the hevy lifting when it comes to security
    if apps.contains(&app) {
        if let Ok(output) = Command::new(app).args(args).output() {
            let stdout = output.stdout;
            _ = write!(out, "{}\0", stdout.len());
            _ = out.write_all(stdout.as_slice());
        }
    }
}

fn info<W: Write>(out: &mut W) {
    if let Ok(n) = available_parallelism() {
        _ = write!(out, "N{}\0", n);
    }
}

