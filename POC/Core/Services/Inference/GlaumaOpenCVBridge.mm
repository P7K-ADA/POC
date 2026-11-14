#import "GlaumaOpenCVBridge.h"
#include <opencv2/core.hpp>
#include <opencv2/imgproc.hpp>
#include <algorithm>
#include <vector>
#include <cmath>
#include <cfloat>
#include <exception>

using namespace cv;

static NSString *GMessage(NSString *code) {
    NSDictionary *messages = @{
        @"NO_FUNDUS": @"Area fundus belum terlihat jelas. Posisikan lensa tepat di depan mata dan ambil foto ulang.",
        @"OVEREXPOSED": @"Foto terlalu terang. Kurangi pencahayaan/flash, atur posisi lensa, lalu ambil ulang.",
        @"UNDEREXPOSED": @"Foto terlalu gelap. Perbaiki pencahayaan dan ambil ulang.",
        @"GLARE": @"Pantulan cahaya menutupi area fundus. Ubah sudut lensa atau pencahayaan, lalu ambil ulang.",
        @"BLUR": @"Foto kurang fokus. Stabilkan HP dan lensa, fokuskan kembali, lalu ambil ulang.",
        @"LOW_CONTRAST": @"Kontras gambar terlalu rendah. Periksa fokus dan pencahayaan, lalu ambil ulang.",
        @"DISC_NOT_FOUND": @"Optic disc tidak berhasil ditemukan. Pastikan fundus terlihat utuh dan fokus, lalu ambil ulang.",
        @"PREPROCESS_FAIL": @"Foto tidak dapat diproses. Silakan ambil foto fundus ulang."
    };
    return messages[code] ?: messages[@"PREPROCESS_FAIL"];
}

static NSData *MatRGBData(const Mat &m) {
    Mat rgb;
    if (m.channels() == 3) rgb = m.isContinuous() ? m : m.clone();
    else cvtColor(m, rgb, COLOR_GRAY2RGB);
    return [NSData dataWithBytes:rgb.data length:rgb.total() * rgb.elemSize()];
}

static double PercentileValues(std::vector<uchar> &values, double p) {
    if (values.empty()) return 0.0;
    size_t k = (size_t)std::round(std::max(0.0, std::min(1.0, p)) * (values.size() - 1));
    std::nth_element(values.begin(), values.begin() + k, values.end());
    return (double)values[k];
}

static double PercentileMasked(const Mat &src, const Mat &mask, double p) {
    std::vector<uchar> values;
    values.reserve((size_t)countNonZero(mask));
    for (int y = 0; y < src.rows; ++y) {
        const uchar *s = src.ptr<uchar>(y);
        const uchar *m = mask.ptr<uchar>(y);
        for (int x = 0; x < src.cols; ++x) if (m[x]) values.push_back(s[x]);
    }
    return PercentileValues(values, p);
}

static double MedianInsideCircle(const Mat &src, int cx, int cy, int radius) {
    std::vector<uchar> values;
    values.reserve((size_t)CV_PI * radius * radius);
    int x0 = std::max(0, cx-radius), x1 = std::min(src.cols-1, cx+radius);
    int y0 = std::max(0, cy-radius), y1 = std::min(src.rows-1, cy+radius);
    const int r2 = radius * radius;
    for (int y = y0; y <= y1; ++y) {
        const uchar *row = src.ptr<uchar>(y);
        for (int x = x0; x <= x1; ++x) {
            int dx = x-cx, dy = y-cy;
            if (dx*dx + dy*dy <= r2) values.push_back(row[x]);
        }
    }
    return PercentileValues(values, 0.50);
}

static Mat LargestFundusMask(const Mat &rgb) {
    Mat gray, mask, labels, stats, centroids;
    cvtColor(rgb, gray, COLOR_RGB2GRAY);
    threshold(gray, mask, 12, 255, THRESH_BINARY);
    morphologyEx(mask, mask, MORPH_CLOSE,
                 getStructuringElement(MORPH_RECT, cv::Size(7, 7)));
    int count = connectedComponentsWithStats(mask, labels, stats, centroids, 8, CV_32S);
    Mat result = Mat::zeros(mask.size(), CV_8U);
    if (count <= 1) return result;
    int best = 1;
    for (int i = 2; i < count; ++i) {
        if (stats.at<int>(i, CC_STAT_AREA) > stats.at<int>(best, CC_STAT_AREA)) best = i;
    }
    compare(labels, best, result, CMP_EQ);
    return result;
}

static NSDictionary *AssessQuality(const Mat &rgb) {
    Mat region = LargestFundusMask(rgb);
    double coverage = (double)countNonZero(region) / (double)region.total();
    if (coverage < 0.08) {
        return @{@"ok": @NO, @"reason": @"NO_FUNDUS",
                 @"metrics": @{@"fundus_coverage": @(coverage)}};
    }

    Mat gray;
    cvtColor(rgb, gray, COLOR_RGB2GRAY);
    Scalar meanValue, stdValue;
    meanStdDev(gray, meanValue, stdValue, region);
    double brightness = meanValue[0];
    double contrast = PercentileMasked(gray, region, 0.95) - PercentileMasked(gray, region, 0.05);

    int total = std::max(1, countNonZero(region));
    int high = 0, low = 0, glare = 0;
    for (int y = 0; y < rgb.rows; ++y) {
        const Vec3b *row = rgb.ptr<Vec3b>(y);
        const uchar *rrow = region.ptr<uchar>(y);
        for (int x = 0; x < rgb.cols; ++x) {
            if (!rrow[x]) continue;
            const Vec3b p = row[x];
            if (p[0] >= 250 && p[1] >= 250 && p[2] >= 250) high++;
            if (p[0] <= 8 && p[1] <= 8 && p[2] <= 8) low++;
            if (p[0] > 245 && p[1] > 245 && p[2] > 245) glare++;
        }
    }
    double highFraction = (double)high / total;
    double lowFraction = (double)low / total;
    double glareFraction = (double)glare / total;

    Mat lap;
    Laplacian(gray, lap, CV_64F);
    Scalar lapMean, lapStd;
    meanStdDev(lap, lapMean, lapStd, region);
    double sharpness = lapStd[0] * lapStd[0];

    NSDictionary *metrics = @{
        @"fundus_coverage": @(coverage),
        @"mean_brightness": @(brightness),
        @"contrast_p95_p5": @(contrast),
        @"high_clip_fraction": @(highFraction),
        @"low_clip_fraction": @(lowFraction),
        @"glare_fraction": @(glareFraction),
        @"laplacian_variance": @(sharpness)
    };

    NSString *reason = nil;
    if (highFraction >= 0.18 || brightness >= 235) reason = @"OVEREXPOSED";
    else if (lowFraction >= 0.45 || brightness <= 30) reason = @"UNDEREXPOSED";
    else if (glareFraction >= 0.15) reason = @"GLARE";
    else if (contrast < 15) reason = @"LOW_CONTRAST";

    if (reason) return @{@"ok": @NO, @"reason": reason, @"metrics": metrics};

    NSMutableArray *actions = [NSMutableArray array];
    if (brightness >= 205 && highFraction < 0.08) [actions addObject:@"gamma_darken"];
    else if (brightness <= 55 && lowFraction < 0.25) [actions addObject:@"gamma_brighten"];
    if (sharpness < 22) [actions addObject:@"mild_sharpen"];

    NSMutableArray *warnings = [NSMutableArray array];
    if (sharpness < 8) [warnings addObject:@"Foto tampak kurang tajam; hasil segmentasi perlu diperiksa."];

    return @{@"ok": @YES,
             @"status": actions.count ? @"recoverable" : @"pass",
             @"actions": actions,
             @"warnings": warnings,
             @"metrics": metrics,
             @"mean_brightness": @(brightness),
             @"sharpness": @(sharpness)};
}

static void ApplyGamma(Mat &im, double gamma) {
    Mat lut(1, 256, CV_8U);
    for (int i = 0; i < 256; ++i) {
        lut.at<uchar>(i) = (uchar)std::max(0.0, std::min(255.0, std::pow(i / 255.0, gamma) * 255.0));
    }
    LUT(im, lut, im);
}

static bool CropFOV(Mat &im, NSDictionary **metadata) {
    Mat gray, blurred, binary;
    cvtColor(im, gray, COLOR_RGB2GRAY);
    cv::GaussianBlur(gray, blurred, cv::Size(9, 9), 0);
    threshold(blurred, binary, 18, 255, THRESH_BINARY);
    std::vector<std::vector<cv::Point>> contours;
    findContours(binary, contours, RETR_EXTERNAL, CHAIN_APPROX_SIMPLE);
    if (contours.empty()) {
        *metadata = @{@"applied": @NO, @"reason": @"FOV_CONTOUR_NOT_FOUND"};
        return false;
    }
    auto largest = *std::max_element(contours.begin(), contours.end(),
        [](const auto &a, const auto &b) { return contourArea(a) < contourArea(b); });
    cv::Point2f center; float radius = 0;
    minEnclosingCircle(largest, center, radius);
    if (radius <= std::min(im.rows, im.cols) * 0.20f) {
        *metadata = @{@"applied": @NO, @"reason": @"FOV_CONTOUR_TOO_SMALL"};
        return false;
    }
    int cx = cvRound(center.x), cy = cvRound(center.y), r = cvRound(radius);
    int x0 = std::max(0, cx-r), y0 = std::max(0, cy-r);
    int x1 = std::min(im.cols, cx+r), y1 = std::min(im.rows, cy+r);
    if (x1-x0 < 16 || y1-y0 < 16) {
        *metadata = @{@"applied": @NO, @"reason": @"FOV_CROP_TOO_SMALL"};
        return false;
    }
    im = im(cv::Rect(x0, y0, x1-x0, y1-y0)).clone();
    *metadata = @{@"applied": @YES, @"center": @[@(cx), @(cy)],
                  @"radius": @(r), @"bbox": @[@(x0), @(y0), @(x1), @(y1)]};
    return true;
}

static bool CropDiscCHT(Mat &im, NSDictionary **metadata) {
    // Match notebook crop_disc_roi_joiv_cht():
    // red channel -> median blur 5x5 -> HoughCircles -> highest median red.
    Mat red, detect;
    extractChannel(im, red, 0); // Input is RGB: channel 0 is red.
    medianBlur(red, detect, 5);

    const int minDim = std::min(im.rows, im.cols);
    std::vector<Vec3f> circles;
    HoughCircles(detect, circles, HOUGH_GRADIENT,
                 1.2,
                 std::max(1, (int)(minDim * 0.25)),
                 100, 30,
                 std::max(1, (int)(minDim * 0.07)),
                 std::max(2, (int)(minDim * 0.45)));

    if (circles.empty()) {
        *metadata = @{@"success": @NO, @"reason": @"CHT_NO_CIRCLE"};
        return false;
    }

    double bestMedian = -DBL_MAX;
    int bestCX = -1, bestCY = -1, bestRadius = -1;

    for (const auto &circleValue : circles) {
        const int cx = cvRound(circleValue[0]);
        const int cy = cvRound(circleValue[1]);
        const int radius = cvRound(circleValue[2]);

        if (radius <= 0 || cx < 0 || cy < 0 ||
            cx >= im.cols || cy >= im.rows) {
            continue;
        }

        const double median = MedianInsideCircle(red, cx, cy, radius);
        if (median > bestMedian) {
            bestMedian = median;
            bestCX = cx;
            bestCY = cy;
            bestRadius = radius;
        }
    }

    if (bestRadius <= 0) {
        *metadata = @{@"success": @NO, @"reason": @"CHT_INVALID_CANDIDATE"};
        return false;
    }

    // Match notebook's crop geometry: radius * 2.4 diameter.
    const int half = std::max(2, (int)(bestRadius * 2.4 / 2.0));
    int x0 = std::max(0, bestCX - half);
    int x1 = std::min(im.cols, bestCX + half);
    int y0 = std::max(0, bestCY - half);
    int y1 = std::min(im.rows, bestCY + half);

    const int side = std::min(x1 - x0, y1 - y0);
    if (side < 8) {
        *metadata = @{@"success": @NO, @"reason": @"CHT_CROP_TOO_SMALL"};
        return false;
    }

    x1 = x0 + side;
    y1 = y0 + side;
    if (x1 > im.cols) { x1 = im.cols; x0 = im.cols - side; }
    if (y1 > im.rows) { y1 = im.rows; y0 = im.rows - side; }

    im = im(cv::Rect(x0, y0, side, side)).clone();

    *metadata = @{
        @"success": @YES,
        @"center": @[@(bestCX), @(bestCY)],
        @"radius": @(bestRadius),
        @"median_red": @(bestMedian),
        @"bbox": @[@(x0), @(y0), @(x0 + side), @(y0 + side)]
    };
    return true;
}

static bool CropDiscBrightest(Mat &im, NSDictionary **metadata) {
    // Exact fallback strategy from notebook crop_disc_roi():
    // disc_map = 0.7 * green + 0.3 * red; suppress pure-white glare;
    // Gaussian blur 51x51; ignore outer 12%; crop 45% of min dimension.
    if (im.empty() || im.channels() != 3) {
        *metadata = @{@"success": @NO, @"reason": @"FALLBACK_INVALID_IMAGE"};
        return false;
    }

    Mat discMap(im.rows, im.cols, CV_32F);
    for (int y = 0; y < im.rows; ++y) {
        const Vec3b *row = im.ptr<Vec3b>(y);
        float *out = discMap.ptr<float>(y);
        for (int x = 0; x < im.cols; ++x) {
            const float r = row[x][0]; // RGB
            const float g = row[x][1];
            const float b = row[x][2];

            const bool glare = (r > 245.0f && g > 245.0f && b > 245.0f);
            out[x] = glare ? 0.0f : (0.7f * g + 0.3f * r);
        }
    }

    Mat blurred;
    cv::GaussianBlur(discMap, blurred, cv::Size(51, 51), 0);

    const int marginY = (int)(im.rows * 0.12);
    const int marginX = (int)(im.cols * 0.12);
    const int innerW = im.cols - 2 * marginX;
    const int innerH = im.rows - 2 * marginY;

    if (innerW <= 0 || innerH <= 0) {
        *metadata = @{@"success": @NO, @"reason": @"FALLBACK_SEARCH_REGION_TOO_SMALL"};
        return false;
    }

    Mat inner = blurred(cv::Rect(marginX, marginY, innerW, innerH));
    cv::Point maxLoc;
    double maxValue = 0.0;
    cv::minMaxLoc(inner, nullptr, &maxValue, nullptr, &maxLoc);

    const int cx = maxLoc.x + marginX;
    const int cy = maxLoc.y + marginY;

    const int boxSize = (int)(std::min(im.rows, im.cols) * 0.45);
    if (boxSize < 8) {
        *metadata = @{@"success": @NO, @"reason": @"FALLBACK_CROP_TOO_SMALL"};
        return false;
    }

    const int half = boxSize / 2;
    int x0 = std::max(0, cx - half);
    int y0 = std::max(0, cy - half);
    int x1 = std::min(im.cols, x0 + boxSize);
    int y1 = std::min(im.rows, y0 + boxSize);

    if ((x1 - x0) < boxSize) x0 = std::max(0, x1 - boxSize);
    if ((y1 - y0) < boxSize) y0 = std::max(0, y1 - boxSize);

    if (x1 - x0 != boxSize || y1 - y0 != boxSize) {
        *metadata = @{@"success": @NO, @"reason": @"FALLBACK_CROP_OUT_OF_BOUNDS"};
        return false;
    }

    im = im(cv::Rect(x0, y0, boxSize, boxSize)).clone();

    *metadata = @{
        @"success": @YES,
        @"center": @[@(cx), @(cy)],
        @"score": @(maxValue),
        @"crop_box_ratio": @0.45,
        @"bbox": @[@(x0), @(y0), @(x0 + boxSize), @(y0 + boxSize)]
    };
    return true;
}

static void Enhance(Mat &im, Mat *denoisedOut, Mat *claheOut) {
    Mat denoised;
    bilateralFilter(im, denoised, 5, 25, 25);
    Mat lab;
    cvtColor(denoised, lab, COLOR_RGB2Lab);
    std::vector<Mat> channels;
    split(lab, channels);
    cv::Ptr<cv::CLAHE> clahe = cv::createCLAHE(2.0, cv::Size(8, 8));
    clahe->apply(channels[0], channels[0]);
    merge(channels, lab);
    Mat enhanced;
    cvtColor(lab, enhanced, COLOR_Lab2RGB);
    *denoisedOut = denoised;
    *claheOut = enhanced;
}

@implementation GlaumaOpenCVBridge

+ (NSDictionary *)prepareRGB:(NSData *)rgbData
                       width:(NSInteger)width
                      height:(NSInteger)height
         captureDebugStages:(BOOL)captureDebugStages {
    @try {
      try {
        if (width < 2 || height < 2 || rgbData.length != (NSUInteger)(width * height * 3)) {
            NSString *code = @"NO_FUNDUS";
            return @{@"ok": @NO, @"reason": code, @"message": GMessage(code), @"metrics": @{}};
        }

        Mat original((int)height, (int)width, CV_8UC3, (void *)rgbData.bytes);
        original = original.clone();
        const int maxInputDimension = 1024;
        const int largestDimension = std::max(original.cols, original.rows);
        if (largestDimension > maxInputDimension) {
            const double scale = (double)maxInputDimension / (double)largestDimension;
            resize(original, original, cv::Size(), scale, scale, INTER_AREA);
        }
        NSMutableDictionary *stages = [NSMutableDictionary dictionary];
        NSMutableDictionary *stageSizes = [NSMutableDictionary dictionary];
        if (captureDebugStages) {
            stages[@"stage1"] = MatRGBData(original);
            stageSizes[@"stage1"] = @[@(original.cols), @(original.rows)];
        }

        NSDictionary *qc = AssessQuality(original);
        NSDictionary *metrics = qc[@"metrics"] ?: @{};
        if (![qc[@"ok"] boolValue]) {
            NSString *code = qc[@"reason"] ?: @"NO_FUNDUS";
            return @{@"ok": @NO, @"status": @"reject", @"reason": code,
                     @"message": GMessage(code), @"metrics": metrics,
                     @"stages": stages, @"stageSizes": stageSizes};
        }

        Mat corrected = original.clone();
        NSArray *actions = qc[@"actions"] ?: @[];
        for (NSString *action in actions) {
            if ([action isEqualToString:@"gamma_darken"]) ApplyGamma(corrected, 1.20);
            else if ([action isEqualToString:@"gamma_brighten"]) ApplyGamma(corrected, 0.82);
            else if ([action isEqualToString:@"mild_sharpen"]) {
                Mat blurred;
                cv::GaussianBlur(corrected, blurred, cv::Size(0,0), 1.0);
                addWeighted(corrected, 1.35, blurred, -0.35, 0, corrected);
            }
        }
        if (captureDebugStages) {
            stages[@"stage2"] = MatRGBData(corrected);
            stageSizes[@"stage2"] = @[@(corrected.cols), @(corrected.rows)];
        }

        Mat fov = corrected.clone();
        NSDictionary *fovMeta = @{};
        bool fovApplied = CropFOV(fov, &fovMeta);
        if (captureDebugStages) {
            stages[@"stage3"] = MatRGBData(fov);
            stageSizes[@"stage3"] = @[@(fov.cols), @(fov.rows)];
        }

        Mat roi = fov.clone();
        NSDictionary *chtMeta = @{};
        NSDictionary *fallbackMeta = @{};

        bool chtSuccess = CropDiscCHT(roi, &chtMeta);
        bool fallbackUsed = false;

        // Notebook setting: ROI_METHOD = "joiv_cht_fallback".
        // If CHT cannot locate a plausible circle, use crop_disc_roi().
        if (!chtSuccess) {
            roi = fov.clone();
            fallbackUsed = CropDiscBrightest(roi, &fallbackMeta);
        }

        NSDictionary *roiMeta = @{
            @"configured_method": @"joiv_cht_fallback",
            @"method_used": chtSuccess ? @"JOIV-inspired CHT" :
                            (fallbackUsed ? @"glauma_brightest fallback" : @"none"),
            @"cht_success": @(chtSuccess),
            @"fallback_used": @(fallbackUsed),
            @"cht_metadata": chtMeta,
            @"fallback_metadata": fallbackMeta
        };

        // Compose the ROI crop rectangle with the optional FOV crop rectangle.
        // Coordinates are normalized against the resized original input, whose
        // aspect ratio is identical to the upright source image.
        NSArray<NSNumber *> *roiBox = (chtSuccess ? chtMeta[@"bbox"] : fallbackMeta[@"bbox"]);
        NSArray<NSNumber *> *fovBox = fovMeta[@"bbox"];
        int fovX = fovApplied && fovBox.count == 4 ? fovBox[0].intValue : 0;
        int fovY = fovApplied && fovBox.count == 4 ? fovBox[1].intValue : 0;
        int fovW = fovApplied && fovBox.count == 4 ? (fovBox[2].intValue - fovBox[0].intValue) : corrected.cols;
        int fovH = fovApplied && fovBox.count == 4 ? (fovBox[3].intValue - fovBox[1].intValue) : corrected.rows;

        int roiX = roiBox.count == 4 ? roiBox[0].intValue : 0;
        int roiY = roiBox.count == 4 ? roiBox[1].intValue : 0;
        int roiW = roiBox.count == 4 ? (roiBox[2].intValue - roiBox[0].intValue) : 0;
        int roiH = roiBox.count == 4 ? (roiBox[3].intValue - roiBox[1].intValue) : 0;

        const double roiXNorm = (double)(fovX + roiX) / (double)corrected.cols;
        const double roiYNorm = (double)(fovY + roiY) / (double)corrected.rows;
        const double roiWNorm = (double)roiW / (double)corrected.cols;
        const double roiHNorm = (double)roiH / (double)corrected.rows;
        NSArray<NSNumber *> *roiRectNormalized = @[
            @(roiXNorm), @(roiYNorm), @(roiWNorm), @(roiHNorm)
        ];

        if (!chtSuccess && !fallbackUsed) {
            NSString *code = @"DISC_NOT_FOUND";
            return @{@"ok": @NO, @"status": @"reject", @"reason": code,
                     @"message": GMessage(code), @"metrics": metrics,
                     @"fovMetadata": fovMeta, @"roiMetadata": roiMeta,
                     @"warnings": fovApplied ? @[] : @[@"FOV_CROP_SKIPPED"],
                     @"stages": stages, @"stageSizes": stageSizes};
        }
        if (captureDebugStages) {
            stages[@"stage4"] = MatRGBData(roi);
            stageSizes[@"stage4"] = @[@(roi.cols), @(roi.rows)];
        }

        Mat denoised, enhanced;
        Enhance(roi, &denoised, &enhanced);
        if (captureDebugStages) {
            stages[@"stage5"] = MatRGBData(denoised);
            stageSizes[@"stage5"] = @[@(denoised.cols), @(denoised.rows)];
            stages[@"stage6"] = MatRGBData(enhanced);
            stageSizes[@"stage6"] = @[@(enhanced.cols), @(enhanced.rows)];
        }

        Mat finalImage;
        resize(enhanced, finalImage, cv::Size(512,512), 0, 0, INTER_AREA);
        if (captureDebugStages) {
            stages[@"stage7"] = MatRGBData(finalImage);
            stageSizes[@"stage7"] = @[@(finalImage.cols), @(finalImage.rows)];
        }

        NSData *finalData = MatRGBData(finalImage);
        NSMutableArray *warnings = [NSMutableArray array];
        if (!fovApplied) [warnings addObject:@"FOV_CROP_SKIPPED"];
        [warnings addObjectsFromArray:qc[@"warnings"] ?: @[]];
          return @{@"ok": @YES, @"status": qc[@"status"] ?: @"pass",
                 @"metrics": metrics, @"actions": actions,
                 @"rgbData": finalData, @"width": @512, @"height": @512,
                 @"fovMetadata": fovMeta, @"roiMetadata": roiMeta,
                 @"roiRectNormalized": roiRectNormalized,
                 @"warnings": warnings, @"stages": stages, @"stageSizes": stageSizes};
      } catch (const cv::Exception &e) {
        NSString *code = @"PREPROCESS_FAIL";
        return @{@"ok": @NO, @"status": @"reject", @"reason": code,
                 @"message": GMessage(code), @"exception": [NSString stringWithUTF8String:e.what()] ?: @"OpenCV error",
                 @"metrics": @{}};
      } catch (const std::exception &e) {
        NSString *code = @"PREPROCESS_FAIL";
        return @{@"ok": @NO, @"status": @"reject", @"reason": code,
                 @"message": GMessage(code), @"exception": [NSString stringWithUTF8String:e.what()] ?: @"C++ exception",
                 @"metrics": @{}};
      }
    } @catch (NSException *e) {
        NSString *code = @"PREPROCESS_FAIL";
        return @{@"ok": @NO, @"status": @"reject", @"reason": code,
                 @"message": GMessage(code), @"exception": e.reason ?: @"Objective-C exception",
                 @"metrics": @{}};
    }
}
@end
