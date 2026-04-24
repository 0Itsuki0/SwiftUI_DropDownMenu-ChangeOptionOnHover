
import SwiftUI

struct UITestView: View {
    @State private var selectedStyle = "Formal"

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text("Long Press and Drag! \nLike the keyboard globe button!")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.vertical, 8)
            Text("Selected: \(selectedStyle)")
            CustomDropdown(selectedStyle: $selectedStyle)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .center
        )
        .background(.gray.opacity(0.1))
        .ignoresSafeArea()
    }
}

struct CustomDropdown: View {
    let options = ["Formal", "Casual", "Very Casual", "Excited"]

    @State private var dropdownExpanded = false
    @State private var gestureRecognized = false
    @State private var triggerButtonHovering = false
    @State private var menuHovering = false

    @Binding var selectedStyle: String

    private let width: CGFloat = 208
    private let buttonHeight: CGFloat = 44
    private let selectionHeight: CGFloat = 48
    private let dropdownSpacing: CGFloat = 8

    var body: some View {
        Button(
            action: {
                // make sure to not trigger the recording on the press that causes a long-press to be recognized
                if gestureRecognized {
                    gestureRecognized = false
                    return
                }
                self.dropdownExpanded = false
                // do some other stuff!
            },
            label: {
                Image(
                    systemName: "star.fill"
                )
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .padding(.vertical, 8)
            }
        )
        .buttonStyle(CapsuleFillButtonStyle(isDragging: triggerButtonHovering || menuHovering))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Capsule().fill(
                .white
            )
        )
        .frame(width: width, height: buttonHeight)
        .overlay(alignment: .top) {
            if dropdownExpanded {
                dropdown
                    .offset(y: buttonHeight + dropdownSpacing)  // push below button
                    .zIndex(1)
            }
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.2)
                .onEnded({ _ in
                    self.gestureRecognized = true
                    withAnimation {
                        self.dropdownExpanded = true
                    }
                })
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 10)
                .onChanged({ value in
                    guard self.dropdownExpanded else { return }
                    guard !self.menuHovering else { return }
                    self.triggerButtonHovering = true

                    let y = value.location.y - buttonHeight - dropdownSpacing
                    let index = Int(y / selectionHeight)
                    if index >= 0 && index < options.count {
                        self.selectedStyle = options[index]
                    }
                })
                .onEnded({ value in
                    self.triggerButtonHovering = false
                    guard self.dropdownExpanded else { return }
                    guard !self.menuHovering else { return }

                    if isInMenu(
                        x: value.location.x,
                        y: value.location.y - buttonHeight - dropdownSpacing
                    ) {
                        self.dropdownExpanded = false
                    }
                })
        )

    }

    var dropdown: some View {
        VStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button {
                    selectedStyle = option
                    dropdownExpanded = false
                } label: {
                    Text(option)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Capsule())
                        .foregroundStyle(.black)
                        .font(.system(size: 18))
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .frame(height: selectionHeight)
                }
                .buttonStyle(.plain)
                .background {
                    if triggerButtonHovering || menuHovering,
                        selectedStyle == option
                    {
                        Capsule().fill(.gray.opacity(0.7))
                    }
                }
            }
        }
        .padding(.all, 10)
        .background(
            RoundedRectangle(cornerRadius: 28).fill(.white)
        )
        .frame(maxWidth: .infinity)
        // 0 distance so that the highlight can be applied as soon as possible
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged({ value in
                    guard self.dropdownExpanded else { return }
                    guard !self.triggerButtonHovering else { return }

                    self.menuHovering = true
                    let y = value.location.y
                    let index = Int(y / selectionHeight)
                    if index >= 0 && index < options.count {
                        self.selectedStyle = options[index]
                    }
                })
                .onEnded({ value in
                    self.menuHovering = false
                    guard self.dropdownExpanded else { return }
                    guard !self.triggerButtonHovering else { return }

                    if isInMenu(x: value.location.x, y: value.location.y) {
                        self.dropdownExpanded = false
                    }
                })
        )
    }

    private func isInMenu(x: CGFloat, y: CGFloat) -> Bool {
        let threshold = 10.0
        if !(-threshold...threshold + width).contains(x) {
            return false
        }
        if !(-threshold...threshold + selectionHeight * CGFloat(options.count))
            .contains(y)
        {
            return false
        }

        return true
    }
}


struct CapsuleFillButtonStyle: ButtonStyle {
    // Needed so that we are not applying background if the menu is hovering.
    // Otherwise, the trigger button and the menu option might be highlighted simultaneously
    var isDragging: Bool

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .background(
                (configuration.isPressed && !isDragging)
                    ? .gray.opacity(0.7) : .clear
            )
            .clipShape(Capsule())
    }
}
