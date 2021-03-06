//
//  AddCommentClient.swift
//  Freetime
//
//  Created by Ryan Nystrom on 7/15/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import Foundation

protocol AddCommentListener: class {
    func didSendComment(client: AddCommentClient, id: String, commentFields: CommentFields, reactionFields: ReactionFields)
    func didFailSendingComment(client: AddCommentClient, subjectId: String, body: String)
}

final class AddCommentClient {

    private class ListenerWrapper: NSObject {
        weak var listener: AddCommentListener? = nil
    }
    private var listeners = [ListenerWrapper]()
    private let client: GithubClient

    init(client: GithubClient) {
        self.client = client
    }

    // MARK: Public API

    func addListener(listener: AddCommentListener) {
        let wrapper = ListenerWrapper()
        wrapper.listener = listener
        listeners.append(wrapper)
    }

    func addComment(subjectId: String, body: String) {
        client.perform(mutation: AddCommentMutation(subjectId: subjectId, body: body)) { (result, error) in
            if let commentNode = result?.data?.addComment?.commentEdge.node {
                let fragments = commentNode.fragments
                for listener in self.listeners {
                    listener.listener?.didSendComment(
                        client: self,
                        id: fragments.nodeFields.id,
                        commentFields: fragments.commentFields,
                        reactionFields: fragments.reactionFields
                    )
                }
            } else {
                for listener in self.listeners {
                    listener.listener?.didFailSendingComment(client: self, subjectId: subjectId, body: body)
                }
            }

            ShowErrorStatusBar(graphQLErrors: result?.errors, networkError: error)
        }
    }

}
