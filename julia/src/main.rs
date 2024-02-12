use std::{
    env,
    io::{stdout, Result, Write},
    ops::{Add, Mul},
};

#[derive(Clone, Copy)]
struct Complex {
    re: f64,
    im: f64,
}

impl Complex {
    fn abs2(&self) -> f64 {
        self.re * self.re + self.im * self.im
    }

    fn new(re: f64, im: f64) -> Complex {
        Complex { re, im }
    }
}

impl Mul<Complex> for Complex {
    type Output = Complex;

    fn mul(self, other: Complex) -> Complex {
        Complex {
            re: self.re * other.re - self.im * other.im,
            im: self.re * other.im + self.im * other.re,
        }
    }
}

impl Add<Complex> for Complex {
    type Output = Complex;

    fn add(self, other: Complex) -> Complex {
        Complex {
            re: self.re + other.re,
            im: self.im + other.im,
        }
    }
}

fn julia(z: Complex, c: Complex) -> f64 {
    const ITER_MAX: u16 = 1000;
    const Z_MAX2: f64 = 10.0 * 10.0;

    let mut z = z;
    for i in 0..ITER_MAX {
        if z.abs2() > Z_MAX2 {
            return i as f64 / ITER_MAX as f64;
        }
        z = z * z + c;
    }
    return 1.0;
}

fn render<W: Write>(
    out: &mut W,
    xres: u32,
    yres: u32,
    xmin: u32,
    xmax: u32,
    ymin: u32,
    ymax: u32,
) -> Result<()> {
    let c = Complex::new(-0.1, 0.65);

    write!(out, "P5\n")?;
    write!(out, "{} {} {}\n", xres, yres, u8::MAX)?;

    let (rmin, rmax, imin, imax) = (-1.5, 1.5, -1.5, 1.5);
    let dr = (rmax - rmin) / (xres as f64);
    let di = (imax - imin) / (yres as f64);
    for j in ymin..ymax {
        for i in xmin..xmax {
            let z = Complex::new(rmin + (i as f64) * dr, imax - (j as f64) * di);
            out.write_all(&[(255.0 * julia(z, c)) as u8])?;
        }
    }
    out.flush()
}

fn main() {
    let args: Vec<String> = env::args().collect();

    assert!(
        args.len() == 7,
        "ERROR: arguments should be xres yres xmin xmax ymin ymax"
    );
    let xres: u32 = args[1].parse().unwrap();
    let yres: u32 = args[2].parse().unwrap();
    let xmin: u32 = args[3].parse().unwrap();
    let xmax: u32 = args[4].parse().unwrap();
    let ymin: u32 = args[5].parse().unwrap();
    let ymax: u32 = args[6].parse().unwrap();

    render(&mut stdout(), xres, yres, xmin, xmax, ymin, ymax).unwrap()
}
