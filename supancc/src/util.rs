use image::io::Reader;
use slint::{Image, Rgb8Pixel, SharedPixelBuffer};
use std::fs::File;
use std::io::{BufRead, BufReader, Error, Seek};

pub fn load_image<R: BufRead + Seek>(input: R) -> Result<Image, String> {
    // dear authors of image, why did you not implement From<ImageError> for String???!!!
    let rdr = Reader::new(input)
        .with_guessed_format()
        .map_err(|e| e.to_string())?
        .decode()
        .map_err(|e| e.to_string())?;
    let img = rdr.as_rgb8().ok_or("image conversion failed")?;
    let buf =
        SharedPixelBuffer::<Rgb8Pixel>::clone_from_slice(img.as_raw(), img.width(), img.height());
    Ok(Image::from_rgb8(buf))
}

pub fn load_nodes() -> Result<Vec<String>, Error> {
    BufReader::new(File::open("nodes.txt")?).lines().collect()
}
