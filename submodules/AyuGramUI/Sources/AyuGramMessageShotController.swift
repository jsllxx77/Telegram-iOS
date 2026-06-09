import Foundation
import UIKit
import AccountContext
import AyuGramCore
import Postbox
import TelegramCore

public func ayuGramPresentMessageShot(
    context: AccountContext,
    message: Message,
    settings: AyuGramMessageShotSettings,
    sourceView: UIView?
) {
    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
    let image = AyuGramMessageShotRenderer.render(
        message: message,
        presentationData: presentationData,
        settings: settings,
        streamerPolicy: AyuGramStreamerModePolicy(isEnabled: context.isAyuGramStreamerModeEnabled)
    )

    let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
    if let sourceView = sourceView {
        activityController.popoverPresentationController?.sourceView = sourceView
        activityController.popoverPresentationController?.sourceRect = CGRect(
            origin: CGPoint(x: sourceView.bounds.width / 2.0, y: max(1.0, sourceView.bounds.height - 1.0)),
            size: CGSize(width: 1.0, height: 1.0)
        )
    }
    context.sharedContext.applicationBindings.presentNativeController(activityController)
}
