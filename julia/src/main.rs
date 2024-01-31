use std::{
    env,
    ops::{Add, Mul},
    io::{Result, stdout, Write},
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
        Complex {
            re,
            im,
        }
    }
}

impl Mul<Complex> for Complex {
    type Output =  Complex;

    fn mul(self, other: Complex) -> Complex {
        Complex {
            re: self.re*other.re - self.im*other.im,
            im: self.re*other.im + self.im*other.re,
        }
    }
}

impl Add<Complex> for Complex {
    type Output =  Complex;

    fn add(self, other: Complex) -> Complex {
        Complex {
            re: self.re + other.re,
            im: self.im + other.im,
        }
    }
}

fn julia(z: Complex, c: Complex) -> f64 {
    const ITER_MAX: u16 = 1000;
    const Z_MAX2: f64 = 10.0*10.0;

    let mut z = z;
    for i in 0..ITER_MAX {
        if z.abs2() > Z_MAX2 {
            return i as f64 / ITER_MAX as f64;
        }
        z = z*z + c;
    }
    return 1.0;
}

fn render<W: Write>(out: &mut W, rres: u32, ires: u32, rmin: f64, rmax: f64, imin: f64, imax: f64) -> Result<()> {
    let c = Complex::new(-0.1, 0.65);

    write!(out, "P5\n")?;
    write!(out, "{} {} {}\n", rres, ires, u8::MAX)?;

    let dr = (rmax - rmin) / rres as f64;
    let di = (imax - imin) / ires as f64;
    for j in 0..ires {
        for i in 0..rres {
            let z = Complex::new(rmin + (i as f64)*dr, imax - (j as f64)*di);
            out.write_all(&[(255.0 * julia(z, c)) as u8])?;
        }
    }
    out.flush()
}

fn main() {
    let args: Vec<String> = env::args().collect();

    assert!(args.len() == 7, "ERROR: arguments should be rres ires rmin rmax imin imax");
    let rres: u32 = args[1].parse().unwrap();
    let ires: u32 = args[2].parse().unwrap();
    let rmin: f64 = args[3].parse().unwrap();
    let rmax: f64 = args[4].parse().unwrap();
    let imin: f64 = args[5].parse().unwrap();
    let imax: f64 = args[6].parse().unwrap();

    render(&mut stdout(), rres, ires, rmin, rmax, imin, imax).unwrap()
}
