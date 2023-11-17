#include <iostream>
#include <complex>

using namespace std;

double julia(complex<double> z, complex<double> c) {
    const int ITER_MAX = 1000;
    const double Z_MAX = 10;

    int i = 0;
    for(; i < ITER_MAX && abs(z) < Z_MAX; i++)
        z = z*z + c;

    return ((double) i) / ITER_MAX;
}


int main(int argc, char** argv) {
    if (argc != 7) {
        cerr << "expected: Re_res Im_res Re_min Re_max Im_min Im_max" << endl;
        return 1;
    }

    int rres = atoi(argv[1]);
    int ires = atoi(argv[2]);
    double rmin = atof(argv[3]);
    double rmax = atof(argv[4]);
    double imin = atof(argv[5]);
    double imax = atof(argv[6]);

    auto c = complex<double>(-0.1, 0.65);

    cout << "P5" << endl;
    cout << rres << ' ' << ires << ' ' << 255 << endl;

    double dr = (rmax - rmin) / rres;
    double di = (imax - imin) / ires;
    for (int j = 0; j < ires; j++) {
        for (int i = 0; i < rres; i++) {
            auto z = complex<double>(rmin + i*dr, imax - j*di);
            cout << (char) (255 * julia(z, c));
        }
    }

    return 0;
}
