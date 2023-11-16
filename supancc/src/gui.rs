use std::fs::File;
use std::io::BufReader;

use crate::util::load_image;

pub fn gui_loop() {
    let main_window = MainWindow::new().unwrap();

    let img = load_image(BufReader::new(File::open("out.ppm").unwrap())).unwrap();
    main_window.set_output(img);

    main_window.run().unwrap();
}

slint::slint! {
    import {Button, ComboBox, Slider, VerticalBox, HorizontalBox} from "std-widgets.slint";

    component HSlider inherits Slider {
        height: 30px;
    }

    export component MainWindow inherits Window {
        in property<image> output <=> viewer.source;

        preferred-width: 100px;
        preferred-height: 100px;

        title: "Super-Android Control Centre";

        HorizontalBox{
            viewer := Image { }
            VerticalBox {
                max-width: 320px;
                alignment: center;
                ComboBox { height: 30px; model: ["Menger sponge", "Julia set"]; }
                HSlider { value: 42; }
                HSlider { value: 30; }
                HSlider { value: 80; }
                Button {
                    height: 50px;
                    text: "Render";
                }
            }
        }
    }
}
