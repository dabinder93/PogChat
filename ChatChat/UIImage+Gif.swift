

import UIKit
import ImageIO

extension UIImage {

    public class func gifWithData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("SwiftGif: Source for the image does not exist")
            return nil
        }

        return UIImage.animatedImageWithSource(source)
    }

    public class func gifWithURL(_ gifUrl:String) -> UIImage? {

        guard let bundleURL = URL(string: gifUrl)
            else {
                print("SwiftGif: This image named \"\(gifUrl)\" does not exist")
                return nil
        }


        guard let imageData = try? Data(contentsOf: bundleURL) else {
            print("SwiftGif: Cannot turn image named \"\(gifUrl)\" into NSData")
            return nil
        }

        return gifWithData(imageData)
    }

    public class func gifWithName(_ name: String) -> UIImage? {

        guard let bundleURL = Bundle.main
          .url(forResource: name, withExtension: "gif") else {
            print("SwiftGif: This image named \"\(name)\" does not exist")
            return nil
        }


        guard let imageData = try? Data(contentsOf: bundleURL) else {
            print("SwiftGif: Cannot turn image named \"\(name)\" into NSData")
            return nil
        }

        return gifWithData(imageData)
    }

    class func delayForImageAtIndex(_ index: Int, source: CGImageSource!) -> Double {
        var delay = 0.1


        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifProperties: CFDictionary = unsafeBitCast(
            CFDictionaryGetValue(cfProperties,
                                 Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()),
            to: CFDictionary.self)

        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(gifProperties,
                                 Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
            to: AnyObject.self)
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties,
                                                             Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()),
                                        to: AnyObject.self)
        }

        delay = delayObject as! Double

        if delay < 0.1 {
            delay = 0.1
        }

        return delay
    }

    class func gcdForPair(_ _a: Int?, _ _b: Int?) -> Int {

        if _b == nil || _a == nil {
            if _b != nil {
                return _b!
            } else if _a != nil {
                return _a!
            } else {
                return 0
            }
        }

        var a = _a!
        var b = _b!


        if a < b {
            let c = a
            a = b
            b = c
        }

 
        var rest: Int
        while true {
            rest = a % b

            if rest == 0 {
                return b
            } else {
                a = b
                b = rest
            }
        }
    }

    class func gcdForArray(_ array: Array<Int>) -> Int {
        if array.isEmpty {
            return 1
        }

        var gcd = array[0]

        for val in array {
            gcd = UIImage.gcdForPair(val, gcd)
        }

        return gcd
    }

    class func animatedImageWithSource(_ source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        var images = [CGImage]()
        var delays = [Int]()


        for i in 0..<count {

            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(image)
            }


            let delaySeconds = UIImage.delayForImageAtIndex(Int(i),
                source: source)
            delays.append(Int(delaySeconds * 1000.0))
        }

        let duration: Int = {
            var sum = 0

            for val: Int in delays {
                sum += val
            }

            return sum
            }()


        let gcd = gcdForArray(delays)
        var frames = [UIImage]()

        var frame: UIImage
        var frameCount: Int
        for i in 0..<count {
            frame = UIImage(cgImage: images[Int(i)])
            frameCount = Int(delays[Int(i)] / gcd)

            for _ in 0..<frameCount {
                frames.append(frame)
            }
        }

        let animation = UIImage.animatedImage(with: frames,
            duration: Double(duration) / 1000.0)

        return animation
    }

}
