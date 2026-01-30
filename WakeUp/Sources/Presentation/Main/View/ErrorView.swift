//
//  ErrorView.swift
//  WakeUp
//
//  Created by 이세민 on 1/19/26.
//

import SwiftUI

struct ErrorView: View {
    @State private var isContactFormPresented = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("오류가 발생했습니다\n잠시 후 다시 시도해주세요")
                    .bold22()
                    .padding(.top, 50)
                    .multilineTextAlignment(.center)
                
                Text("오류가 계속된다면\n오른쪽 위의 ‘문의’를 통해 알려주세요.")
                    .semiBold17(color: .gray200)
                    .padding(.top, 12)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                MainButton(title: String(localized: "다시 시도하기"))
            }
            .padding(.horizontal, 16)
            .navigationBarItems(trailing: contactButton)
            .sheet(isPresented: $isContactFormPresented) {
                WebView(url: StringLiteral.AppLinks.contactForm)
            }
        }
    }
}

// MARK: - SubViews

extension ErrorView {
    private var contactButton: some View {
        Button {
            isContactFormPresented.toggle()
        } label: {
            Text("문의")
                .regular15()
        }
    }
}
