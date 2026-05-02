import Foundation
import AVFoundation
import Speech

@MainActor
final class STTService: ObservableObject {
    static let shared = STTService()
    
    weak var delegate: STTDelegate?
    
    @Published var currentTranscript: String = ""
    @Published var isRecording: Bool = false
    @Published var hasPermission: Bool = false
    @Published var status: STTStatus = .idle
    
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    enum STTStatus: String, CaseIterable {
        case idle = "대기 중"
        case requesting = "권한 요청 중"
    }
    
    public init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))
    }
    
    func requestPermission() async {
        if #available(iOS 17.0, *) {
            let status = SFSpeechRecognizer.authorizationStatus()
            hasPermission = (status == .authorized || status == .restricted)
        } else {
            SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
                DispatchQueue.main.async {
                    self?.hasPermission = authStatus == .authorized
                }
            }
        }
    }
    
    func startRecording() async throws {
        if !hasPermission {
            await requestPermission()
            guard hasPermission else { throw STTError.permissionDenied }
        }
        
        guard let recognizer = speechRecognizer else { throw STTError.noRecognizer }
        
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        audioEngine = engine
        self.recognitionRequest = request
        
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        engine.prepare()
        try engine.start()
        
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                let newText = result.bestTranscription.formattedString
                self.currentTranscript = newText
                self.delegate?.sttDidUpdateTranscript(newText, isFinal: result.isFinal)
            }
            if let error = error {
                self.handleError(error)
            }
        }
        
        isRecording = true
        delegate?.sttDidChange(isRecording: true)
    }
    
    func stopRecording() async throws {
        guard let task = recognitionTask else {
            isRecording = false
            delegate?.sttDidChange(isRecording: false)
            return
        }
        
        task.cancel()
        recognitionTask = nil
        
        recognitionRequest = nil
        audioEngine?.stop()
        audioEngine = nil
        recognitionRequest = nil
        
        isRecording = false
        delegate?.sttDidChange(isRecording: false)
    }
    
    private func handleError(_ error: Error) {
        currentTranscript = ""
        status = .idle
        isRecording = false
        delegate?.sttDidFail(error)
    }
}

protocol STTDelegate: AnyObject {
    func sttDidUpdateTranscript(_ text: String, isFinal: Bool)
    func sttDidCompleteTranscript(_ text: String)
    func sttDidChange(isRecording: Bool)
    func sttDidFail(_ error: Error)
}

enum STTError: LocalizedError {
    case permissionDenied, noRecognizer, noInputNode, recordingFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied: return "음성 인식 권한이 필요합니다"
        case .noRecognizer: return "음성 인식기를 사용할 수 없습니다"
        case .noInputNode: return "오디오 입력 장치를 사용할 수 없습니다"
        case .recordingFailed: return "녹음 시작에 실패했습니다"
        }
    }
}
