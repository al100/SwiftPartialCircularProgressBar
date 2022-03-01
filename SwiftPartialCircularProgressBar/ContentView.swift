//
//  ContentView.swift
//  SwiftPartialCircularProgressBar
//
//  Created by alireza momeni on 3/1/22.
//

import SwiftUI

struct ContentView: View {
    @State var progressValue: Float = 0.3
    @State var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var degress: Double = 0
    @State private var timerTick = false
    @State private var progressFrom: Float = 0.3
    @State private var progressTo: Float = 0.6 // this value should be larger than progressFrom
    @State private var steps: Int = 20
    @State var stepValues : [Float] = []
    @State private var rotation: Float = 0.0
    @State private var rotationClose: Float = 360.0
    @State var x : Float = 0
    @State var s : Float = 0
    @State private var showingAlert = false
    @State private var configOn = true
    @State private var indicator = true
    @State private var colorPicker = false
    @State var results : [Result] = []
    @State var angularGradient : AngularGradient?
    
    struct Result : Equatable{
        var id = UUID()
        var percentage: Float
        var color: Color
    }
    
    func createStepsGradientStops (){
        for step in stepValues {
            let result = Result(id: UUID.init(), percentage: step, color: .white)
            results.append(result)
        }
    }
    
    func bindColors () {
        var stops : [Gradient.Stop] = []
        
        for result in results {
            if result.color != .white {
                let stop : Gradient.Stop = .init(color: result.color, location: CGFloat(result.percentage))
                stops.append(stop)
            }
        }
        angularGradient = AngularGradient(gradient: Gradient(stops: stops.sorted {$0.location < $1.location}), center: .center)
    }
    
    
    var body: some View {
        VStack {
            
            ZStack{
         
                ProgressBar(progress: self.$progressValue , progressFrom: self.$progressFrom , progressTo: self.$progressTo, rotation: self.$rotation, angularGradient: self.$angularGradient)
                    .frame(width: 250.0, height: 250.0)
                    .onReceive(timer) { _ in
                        withAnimation {
                            if timerTick && progressValue <= stepValues.last! {
                                progressValue += (progressTo - progressFrom) / Float(steps)
                            }
                            // print("progress = \(progressValue)")
                        }
                    }
                if indicator {
                    ProgressBarTriangle(progress: self.$progressValue).frame(width: 280.0, height: 290.0).rotationEffect(.degrees(degress), anchor: .bottom)
                        .offset(x: 0, y: -150).onReceive(timer) { input in
                            withAnimation(.easeIn(duration: 0.01).speed(20)) {
                                let endDegree = Double(((progressTo - progressFrom) * 360) / 2)
                                let indicatorSteps = Double((progressTo - progressFrom) * 360) / Double(steps)
                                
                                if timerTick && degress < endDegree {
                                    degress += indicatorSteps
                                }
                               // print("degree = \(indicatorSteps)")
                            }
                        }
                }
            }
            HStack{
                Spacer()
                if configOn {
                    VStack{
                        HStack{
                            Toggle("Timer", isOn: $timerTick)
                                .toggleStyle(SwitchToggleStyle(tint: .cyan)).onChange(of: self.timerTick) { newValue in
                                    if timerTick {
                                        timer =  Timer.publish(every: 1, on: .main, in: .common).autoconnect()
                                    }else {
                                        timer.upstream.connect().cancel()
                                    }
                                }
                            Spacer()
                        }
                        Group{
                            HStack{
                                Text("From")
                                Spacer()
                            }
                            TextField("from", value: $progressFrom, format: .number).textFieldStyle(.roundedBorder)
                        }
                        Group{
                            HStack {
                                Text("To")
                                Spacer()
                            }
                            TextField("to", value: $progressTo, format: .number).textFieldStyle(.roundedBorder)
                        }
                        Group{
                            HStack {
                                Text("Steps")
                                Spacer()
                            }
                            TextField("", value: $steps , formatter: NumberFormatter() , onEditingChanged: {newVal in
                                
                            }, onCommit: {
                                calculateSteps()
                            }).textFieldStyle(.roundedBorder)
                            
                        }
                        HStack {
                            Text("angle currection: \(String(format: "%.2f", x))").font(.caption)
                            Spacer()
                        }
                        
                        
                        Spacer()
                    }.frame(width: 150 , height: 400 , alignment: .center)
                    
                    
                }
                Spacer()
                VStack{
                    //  steps color list
                    List(stepValues.indexed(), id: \.1.self){ idx , data in
                        
                        HStack{
                            Text("\(idx + 1): \(String(format: "%.2f", data))")
                        Button(action: {
                            //bindColors()
                        }) {
                            ColorPicker("", selection: self.$results[idx ].projectedValue.color).onChange(of: results){ newValue in
                                bindColors()
                            }
                        }
                        }
                    }.onAppear {
                        UITableView.appearance().backgroundColor = UIColor.clear
                        UITableView.appearance().contentInset.top = -35
                        calculateSteps()
                    }.background(.white)
                    
                    
                    
                }.frame(width: 200, height: 400, alignment: .center).background(.white)
                
            }
            
            // reset button
            Button {
                reset()
            } label: {
                Text("Reset")
            }.frame(width: 300, height: 40, alignment: .center).cornerRadius(8).background(Color.red).foregroundColor(.white)
            
            
            Spacer()
        }.onAppear {
            
            calculateSteps()
            
            calculateRightAngle()
            
        }.onChange(of: self.progressTo) { newValue in
            if (progressTo > progressFrom){
                
                calculateRightAngle()
                
            }else {
                //alert
                showingAlert = true
            }
        }.alert(isPresented: $showingAlert) {
            Alert(title: Text("warning"), message: Text("to value should be greater than from value"), dismissButton: .default(Text("ok")))
        }
    }
    
    
    fileprivate func calculateRightAngle() {
        s = Float(((progressTo - progressFrom) * 360) - 180)
        if (s > 0){ // extra side more than 180 degrees
            let to360 = ((1 - progressTo) * 10) * 36
            x = to360 + s/2
            rotation = Float(x)
        }
        if (s == 0) {
            x = 360 - (Float(progressTo) * 10) * 36
            rotation = Float(x)
        }
        if (s < 0){
            let to360 = ((1 - progressTo) * 10) * 36
            x = to360 - abs(s/2)
            rotation = Float(x)
        }
        
        degress = Double(((progressTo - progressFrom) * 360) / 2) * -1
    }
    
    
    fileprivate func calculateSteps() {
        stepValues = []
        let stepDiff = (progressTo - progressFrom) / Float(steps)
        stepValues.append(progressFrom)
        for _ in 1..<steps {
            let newAdded = self.stepValues.last! + stepDiff
            self.stepValues.append(newAdded)
        }
        
        createStepsGradientStops()
        bindColors ()
    }
    
    fileprivate func reset() {
        progressValue = 0.3
        degress = 0
        timerTick = false
        progressFrom = 0.3
        progressTo = 0.6
        steps = 20
        stepValues = []
        rotation = 0.0
        rotationClose = 360.0
        x  = 0
        s  = 0
        showingAlert = false
        results = []
        timer.upstream.connect().cancel()
        
        calculateSteps()
        
        calculateRightAngle()
    }
    
    
    struct ProgressBar: View {
        @Binding var progress: Float
        @Binding var progressFrom: Float
        @Binding var progressTo: Float
        @Binding var rotation: Float
        @Binding var angularGradient : AngularGradient?
        
        var body: some View {
            ZStack {
                Circle()
                    .trim(from: CGFloat(self.progressFrom), to: CGFloat(self.progressTo)).stroke(style: StrokeStyle(lineWidth: 12.0, lineCap: .round, lineJoin: .round))
                    .opacity(0.3)
                    .foregroundColor(Color.gray)
                    .rotationEffect(.degrees(Double(self.rotation)))
                
                Circle()
                    .trim(from: CGFloat(progressFrom), to: CGFloat(self.progress))
                    .stroke(style: StrokeStyle(lineWidth: 12.0, lineCap: .round, lineJoin: .round))
                    .fill(self.angularGradient ?? AngularGradient(gradient: Gradient(stops: [
                        .init(color: Color.init(hex: "ED4D4D"), location: 0.39000002),
                        .init(color: Color.init(hex: "E59148"), location: 0.48000002),
                        .init(color: Color.init(hex: "EFBF39"), location: 0.5999999),
                        .init(color: Color.init(hex: "EEED56"), location: 0.7199998),
                        .init(color: Color.init(hex: "32E1A0"), location: 0.8099997)]), center: .center))
                    .rotationEffect(.degrees(Double(self.rotation)))
                
                VStack{
                    Text("824").font(Font.system(size: 44)).bold().foregroundColor(Color.init(hex: "314058"))
                    Text("Great Score!").bold().foregroundColor(Color.init(hex: "32E1A0"))
                }
            }
        }
    }
    
    struct ProgressBarTriangle: View {
        @Binding var progress: Float
        
        var body: some View {
            ZStack {
                
                Image("triangle").resizable().frame(width: 10, height: 10, alignment: .center)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        ContentView(angularGradient: AngularGradient(gradient: Gradient(stops: [
            .init(color: Color.init(hex: "ED4D4D"), location: 0.39000002),
            .init(color: Color.init(hex: "E59148"), location: 0.48000002),
            .init(color: Color.init(hex: "EFBF39"), location: 0.5999999),
            .init(color: Color.init(hex: "EEED56"), location: 0.7199998),
            .init(color: Color.init(hex: "32E1A0"), location: 0.8099997)]), center: .center))
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}



// This is taken from the Release Notes, with a typo correction, marked below
struct IndexedCollection<Base: RandomAccessCollection>: RandomAccessCollection {
    typealias Index = Base.Index
    typealias Element = (index: Index, element: Base.Element)
    
    let base: Base
    
    var startIndex: Index { base.startIndex }
    
    // corrected typo: base.endIndex, instead of base.startIndex
    var endIndex: Index { base.endIndex }
    
    func index(after i: Index) -> Index {
        base.index(after: i)
    }
    
    func index(before i: Index) -> Index {
        base.index(before: i)
    }
    
    func index(_ i: Index, offsetBy distance: Int) -> Index {
        base.index(i, offsetBy: distance)
    }
    
    subscript(position: Index) -> Element {
        (index: position, element: base[position])
    }
}

extension RandomAccessCollection {
    func indexed() -> IndexedCollection<Self> {
        IndexedCollection(base: self)
    }
}
