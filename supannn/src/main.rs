/*
 * YE WHO ENTRE HERE, WELCOME TO THE SPAGHETTI MESS, NOT PROUD OF THIS
 * ONE BUT CAN'T BE BOTHERED...
 *                                           -- Evert
 */

use std::fs::File;
use std::io::{BufRead, BufReader, Error, Read, Write};
use std::net::{Shutdown, TcpListener, TcpStream};
use std::process::{Command, Stdio};
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::Duration;

fn main() {
    let apps = load_apps().expect("failed to load apps.txt");
    let listener = TcpListener::bind("0.0.0.0:31337").unwrap();

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
                    if req.len() > 1 + 1 {
                        if let Ok(str) = String::from_utf8(req[1..req.len() - 1].to_vec()) {
                            let mut args = str.split_whitespace();
                            if let Some(app) = args.next() {
                                run_app(
                                    stream,
                                    app.to_string(),
                                    args.map(|s| s.to_string()).collect(),
                                    apps,
                                );
                            }
                        }
                    }
                }
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

fn run_app(stream: &mut TcpStream, app: String, args: Vec<String>, apps: &Vec<String>) {
    // This line does all the heavy lifting when it comes to security
    if apps.contains(&app) {
        if let Ok(mut child) = Command::new(app)
            .env("PATH", ".")
            .args(args)
            .stdout(Stdio::piped())
            .spawn()
        {
            // Create a buffer which actively reads from child stdout
            // as child does not stop if the output buffer is not empty
            // Hack #1
            if let Some(mut stdout) = child.stdout.take() {
                let buffer = Arc::new(Mutex::new(Vec::new()));
                let buffer_in = Arc::clone(&buffer);

                let reader = thread::spawn(move || {
                    if let Ok(mut buffer) = buffer_in.lock() {
                        let _ = stdout.read_to_end(&mut buffer);
                    }
                });

                // Active waiting as event driven stuff is hard/impossible
                // Hack #2
                loop {
                    // Child process done?
                    match child.try_wait() {
                        Ok(Some(status)) => {
                            if !status.success() {
                                return;
                            } else {
                                if let Ok(_) = reader.join() {
                                    if let Ok(outp) = buffer.lock() {
                                        _ = write!(stream, "{}\0", outp.len());
                                        _ = stream.write_all(outp.as_slice());
                                    }
                                }
                                return;
                            }
                        }
                        Err(_) => {
                            return;
                        }
                        Ok(None) => {}
                    }

                    // Is connection closed?
                    if let Err(_) = stream.write(&[b'\0']) {
                        // Kill child
                        let _ = child.kill();
                        let _ = child.wait();
                        // Clean up reader
                        let _ = reader.join();
                        return;
                    }

                    // Give the process some time
                    thread::sleep(Duration::from_millis(100));
                }
            }
        }
    }
}

fn info(stream: &mut TcpStream) {
    if let Ok(n) = thread::available_parallelism() {
        _ = write!(stream, "N{}\0", n);
    }
}
