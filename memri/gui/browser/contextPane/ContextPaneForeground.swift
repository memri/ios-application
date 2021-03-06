//
// ContextPaneForeground.swift
// Copyright © 2020 memri. All rights reserved.

import SwiftUI

struct ContextPaneForeground: View {
    @EnvironmentObject var context: MemriContext

    var paddingLeft: CGFloat = 25

    var body: some View {
        let context = self.context
        let labels = context.currentView?.resultSet
            .singletonItem?.edges("label")?.itemsArray(type: Label.self) ?? []
        let addLabelAction = ActionNoop(context)

        return
            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text(context.currentView?.title ?? "") // TODO: make this generic
                            .font(.system(size: 23, weight: .regular, design: .default))
                            .fontWeight(.bold)
                            .opacity(0.75)
                            .padding(.horizontal, paddingLeft)
                            .padding(.vertical, 5)
                        Text(context.currentView?.subtitle ?? "")
                            .font(.body)
                            .opacity(0.75)
                            .padding(.horizontal, paddingLeft)

                        HStack {
                            ForEach(context.currentView?.contextPane.buttons ?? [],
                                    id: \.transientUID) { actionItem in
                                ActionButton(action: actionItem)
                            }
                        }
                        .padding(.horizontal, paddingLeft)
                        .padding(.bottom, 15)

                        Divider()
                        (context.item?.functions["describeChangelog"]?(nil) as? String)
                            .map { description in
                                Text(description)
                            }
                            .padding(.horizontal, paddingLeft)
                            .padding(.vertical, 10)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 14, weight: .regular, design: .default))
                            .opacity(0.6)
                        Divider()
                    }
                    HStack {
                        Text(NSLocalizedString("actionLabel", comment: ""))
                            .fontWeight(.bold)
                            .opacity(0.4)
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .padding(.horizontal, paddingLeft)
                        Spacer()
                    }
                    .padding(.top, 15)
                    .padding(.bottom, 10)
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(context.currentView?.contextPane.actions ?? [],
                                id: \.transientUID) { actionItem in
                            Button(action: {
                                context.executeAction(actionItem)
                            }) {
                                Text(actionItem.getString("title"))
                                    .foregroundColor(Color(.label))
                                    .opacity(0.6)
                                    .font(.system(size: 20, weight: .regular, design: .default))
                                    .padding(.vertical, 10)
                            }
                        }
                    }
                    .padding(.horizontal, self.paddingLeft)
                    Divider()
                    HStack {
                        Text(NSLocalizedString("navigateLabel", comment: ""))
                            .fontWeight(.bold)
                            .opacity(0.4)
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .padding(.horizontal, paddingLeft)
                        Spacer()
                    }
                    .padding(.top, 15)
                    .padding(.bottom, 10)
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(context.currentView?.contextPane.navigate ?? [],
                                id: \.transientUID) { navigateItem in
                            Button(action: {
                                context.executeAction(navigateItem)
                            }) {
                                Text(LocalizedStringKey(navigateItem.getString("title")))
                                    .foregroundColor(Color(.label))
                                    .opacity(0.6)
                                    .font(.system(size: 20, weight: .regular, design: .default))
                                    .padding(.vertical, 10)
                            }
                            .padding(.horizontal, self.paddingLeft)
                        }
                    }
                    Divider()
                    HStack {
                        Text(NSLocalizedString("labelsLabel", comment: ""))
                            .fontWeight(.bold)
                            .opacity(0.4)
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .padding(.horizontal, paddingLeft)
                        Spacer()
                    }
                    .padding(.top, 15)
                    .padding(.bottom, 15)
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(labels) { labelItem in
                            Button(action: {
                                context.executeAction(addLabelAction, with: labelItem)
                            }) {
                                Text(labelItem.name ?? "")
                                    .foregroundColor(Color(.label))
                                    .opacity(0.6)
                                    .font(.system(size: 20, weight: .regular, design: .default))
                                    .padding(.vertical, 5)
                                    .padding(.horizontal, 15)
                                    .frame(minWidth: 150, alignment: .leading)
                            }
                            .background(Color(hex: labelItem.color ?? "#ffd966ff"))
                            .cornerRadius(5)
                            .padding(.horizontal, self.paddingLeft)
                        }
                        Button(action: {
                            context.executeAction(ActionNoop(context))
                        }) {
                            Text(addLabelAction.getString("title"))
                                .foregroundColor(Color(.label))
                                .opacity(0.6)
                                .font(.system(size: 20, weight: .regular, design: .default))
                                .padding(.vertical, 10)
                        }
                        .padding(.horizontal, self.paddingLeft)
                    }
                    Spacer()
                }
                .padding(.top, 60)
            }
            .background(Color(.secondarySystemGroupedBackground))
    }
}

struct ForgroundContextPane_Previews: PreviewProvider {
    static var previews: some View {
        ContextPaneForeground().environmentObject(try! RootContext(name: "").mockBoot())
    }
}
