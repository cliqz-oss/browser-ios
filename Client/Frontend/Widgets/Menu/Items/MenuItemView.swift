/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

/**
 * creates a view that consists of an image and a title.
 * the image view is displayed at the center top of the
 **/
class MenuItemCollectionViewCell: UICollectionViewCell {

    var padding: CGFloat = 5.0

    lazy var menuImageView: UIImageView = UIImageView()
    lazy var menuTitleLabel: UILabel = {
        let menuTitleLabel = UILabel()
        menuTitleLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        menuTitleLabel.numberOfLines = 0
        menuTitleLabel.textAlignment = NSTextAlignment.Center
        menuTitleLabel.minimumScaleFactor = 0.15
        if #available(iOS 9, *) {
            menuTitleLabel.allowsDefaultTighteningForTruncation = true
        }
        return menuTitleLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(menuImageView)

        self.contentView.addSubview(menuTitleLabel)

        menuImageView.snp_makeConstraints { make in
            make.centerX.equalTo(self)
            make.bottom.equalTo(self.snp_centerYWithinMargins)
        }

        // for iPhone 5S and below, left/right offset should be padding
        // otherwise it should be 2*padding to make the text wrapping look right.
        let horizontalOffset: CGFloat
        if UIScreen.mainScreen().coordinateSpace.bounds.width < 375 {
            horizontalOffset = padding
        } else {
            horizontalOffset = 2 * padding
        }
        menuTitleLabel.snp_makeConstraints { make in
            make.top.equalTo(menuImageView.snp_bottom).offset(padding)
            make.centerX.equalTo(self)
            make.leading.lessThanOrEqualTo(self).offset(horizontalOffset)
            make.trailing.lessThanOrEqualTo(self).offset(-horizontalOffset)
        }

        self.isAccessibilityElement = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        menuTitleLabel.adjustFontSizeToFit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        menuImageView.image = nil
        menuTitleLabel.text = nil
    }
}

private extension UILabel {

    // this function finds the minimum font size required in order to display
    // individual words on 1 line of the label
    // if there is a single word in the label text that would need to wrap at the existing font size, we will shrink
    // the text until it does fit, then apply that new font size to the entire label.
    func adjustFontSizeToFit() {
        var font = self.font
        let size = systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        guard let words = text?.characters.split(" ").map(String.init) else { return }
        let minimumFontSize = font.pointSize - (font.pointSize * self.minimumScaleFactor)

        var newFontSize = CGFloat.max
        // chunk into single words
        // this is because trying to get an accurate size on more than 1 line at a time using boundingRectWithSize seems impossible
        for word in words {
            var maxFontSize = font.pointSize
            while maxFontSize >= minimumFontSize {
                font = font.fontWithSize(maxFontSize)
                let constraintSize = CGSize(width: .max, height: size.height)
                let labelSize = word.boundingRectWithSize(constraintSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
                if labelSize.width <= size.width {
                    break
                }
                maxFontSize -= 0.5
            }
            newFontSize = min(CGFloat(maxFontSize), newFontSize)
        }
        self.font = font.fontWithSize(newFontSize)
    }
}
