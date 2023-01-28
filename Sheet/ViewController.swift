//
//  ViewController.swift
//  Sheet
//
//  Created by 吴哲 on 2023/1/28.
//

import UIKit
class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .yellow
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        let sheet = SheetViewController(title: "Sheet", message: "I'm a Sheet I'm a Sheet I'm a Sheet I'm a Sheet I'm a Sheet I'm a Sheet I'm a Sheet I'm a Sheet I'm a Sheet I'm a Sheet I'm a Sheet I'm a Sheet I'm a Sheet I'm a Sheet")
//        sheet.actionHeight = 44
        sheet.horizontalPadding = 10
        sheet.actionCornerRadius = 10
//        sheet.backgrounColor = .white.withAlphaComponent(0.8)
//        sheet.ambientColor = .white
        sheet.addAction(.init(title: "A"))
        sheet.addAction(.init(title: "B"))
        sheet.addAction(.init(title: "C"))
        sheet.addAction(.init(title: "D"))
        sheet.addAction(.init(title: "destructive", style: .destructive))
        sheet.addAction(.init(title: "cancel", style: .cancel))
        sheet.show(safeArea: false)

        let sheet2 = SheetViewController()
        sheet2.horizontalPadding = 10
        sheet2.actionCornerRadius = 10
        sheet2.addAction(.init(title: "A"))
        sheet2.addAction(.init(title: "B"))
        sheet2.show()
    }
}
