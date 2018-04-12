//
//  LuminaTextPromptView.swift
//  Lumina
//
//  Created by David Okun on 5/7/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import UIKit

final class LuminaTextPromptView: UIView {

    private var textLabel = UILabel()

	private lazy var blurView: UIVisualEffectView? = {
		var blurEffect: UIBlurEffect = UIBlurEffect()

		if #available(iOS 10.0, *) { //iOS 10.0 and above
			blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)//prominent,regular,extraLight, light, dark
		} else { //iOS 8.0 and above
			blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark) //extraLight, light, dark
		}
		let bView = UIVisualEffectView(effect: blurEffect)
		bView.frame = self.frame //your view that have any objects
		bView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

		return bView
	}()

	static private let animationDuration = 0.3

    init() {
        super.init(frame: CGRect.zero)

		if let bView = self.blurView {
			self.addSubview(bView)
		}

		self.textLabel = UILabel()
        self.textLabel.backgroundColor = UIColor.clear

		self.textLabel.textColor = UIColor.darkText
        self.textLabel.textAlignment = .center
		self.textLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 24)
		self.textLabel.numberOfLines = 0
		self.textLabel.lineBreakMode = .byWordWrapping

        self.addSubview(textLabel)
		self.backgroundColor = UIColor.clear
		self.alpha = 0.0
    }

    func updateText(to text: String) {
        DispatchQueue.main.async {
            if text.isEmpty {
                self.hide(andErase: true)
            } else {
				self.textLabel.text = text
                self.makeAppear()
            }
        }
    }
	func hide(andErase: Bool) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: LuminaTextPromptView.animationDuration, animations: {
                self.alpha = 0.0
            }, completion: { _ in
                if andErase {
                    self.textLabel.text = ""
                }
            })
        }
    }

    private func makeAppear() {
        DispatchQueue.main.async {

			UIView.animate(withDuration: LuminaTextPromptView.animationDuration) {
                self.alpha = 1
            }
        }
    }

    override func layoutSubviews() {
		let margin: CGFloat = 4.0
		var minY = self.frame.minY
		if #available(iOS 11, *) {
			minY = self.safeAreaLayoutGuide.layoutFrame.minY
		}
        self.textLabel.frame = CGRect(origin: CGPoint(x: margin, y: minY + margin), size: CGSize(width: frame.width - 2 * margin, height: frame.height - 2 * margin - minY))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
