use std::env;
use std::io;

use srray::camera::Camera;
use srray::color::Color;
use srray::fractals::SDFMengerSponge;
use srray::geometries::Plane;
use srray::light::PointLight;
use srray::materials::{None, PhongMaterial};
use srray::objects::Object;
use srray::point::Point;
use srray::scene::Scene;
use srray::sdf::{SDFMarcher, SDFRotate};
use srray::vector::Vector;

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

    let camera = Camera {
        origin: Point::new(0., 0., 2.),
        azimuth: 0.,
        altitude: 0.,
        width: xres,
        height: yres,
        fov: 50.,
        spp: 8,
    };

    let scene = Scene {
        max_bounces: 5,
        objects: vec![
            Object {
                geometry: Box::new(SDFMarcher {
                    sdf: Box::new(SDFRotate {
                        sdf: Box::new(SDFMengerSponge { iterations: 5 }),
                        pitch: 40.,
                        yaw: 35.,
                        roll: 0.,
                        reference: Point::ORIGIN,
                    }),
                    max_iterations: 128,
                    max_distance: 20.,
                    tolerance: 1e-5,
                }),
                material: Box::new(PhongMaterial {
                    ambient_color: Color::new(0.02, 0.02, 0.02),
                    diffuse_color: Color::new(0.5, 0.5, 0.5),
                    specular_color: Color::new(2., 2., 2.),
                    specular_power: 50.,
                }),
            },
            Object {
                geometry: Box::new(Plane {
                    origin: Point::new(0., -2., 0.),
                    normal: Vector::new(0., 1., 1.),
                }),
                material: Box::new(PhongMaterial {
                    ambient_color: Color::BLACK,
                    diffuse_color: Color::new(0.1, 0.1, 0.1),
                    specular_color: Color::new(1., 1., 1.),
                    specular_power: 1.,
                }),
            },
        ],
        lights: vec![
            Box::new(PointLight {
                center: Point::new(-2., 1., 2.),
                color: Color::new(4., 2., 2.),
            }),
            Box::new(PointLight {
                center: Point::new(2., 1., 2.),
                color: Color::new(2., 2., 5.),
            }),
        ],
        background: Box::new(None {}),
    };

    camera
        .render_section(&scene, xmin, xmax, ymin, ymax)
        .write_binary_ppm(&mut io::stdout().lock())
        .unwrap();
}
