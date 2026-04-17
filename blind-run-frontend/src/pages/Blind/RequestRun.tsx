import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../../lib/firebase';
import { Mic, CheckCircle, XCircle, Waves, ArrowLeft, Volume2 } from 'lucide-react';
import { speakText } from '../../lib/speech';

export default function RequestRun() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [location, setLocation] = useState('');
  const [time, setTime] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [step, setStep] = useState<'idle' | 'prompting' | 'listening' | 'confirming'>('idle');
  
  const recognitionRef = useRef<any>(null);
  const fallbackTimerRef = useRef<any>(null);
  const stepRef = useRef(step);

  useEffect(() => {
    stepRef.current = step;
  }, [step]);

  useEffect(() => {
    speakText("预约界面。请点击屏幕中央开始语音预约。");
    return () => {
      if ('speechSynthesis' in window) {
        window.speechSynthesis.cancel();
      }
    };
  }, []);

  const processTranscript = (transcript: string) => {
    let parsedLocation = '朝阳公园';
    if (transcript.includes('奥森')) parsedLocation = '奥森公园';
    else if (transcript.includes('天坛')) parsedLocation = '天坛公园';
    else if (transcript.includes('小区')) parsedLocation = '小区跑道';
    
    let parsedTime = '现在出发';
    if (transcript.includes('半小时') || transcript.includes('30分')) parsedTime = '30分钟后';
    else if (transcript.includes('明天')) parsedTime = '明天上午';

    setLocation(parsedLocation);
    setTime(parsedTime);
    
    setStep('confirming');
    speakText(`已为您识别：${parsedLocation}，${parsedTime}。点击屏幕上半部分确认预约，点击下半部分重新录音。`);
  };

  const startRecognition = () => {
    const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
    if (!SpeechRecognition) return;

    setStep('listening');
    stepRef.current = 'listening';
    
    try {
      const recognition = new SpeechRecognition();
      recognitionRef.current = recognition;
      recognition.lang = 'zh-CN';
      
      recognition.onresult = (event: any) => {
        clearTimeout(fallbackTimerRef.current);
        const transcript = event.results[0][0].transcript;
        processTranscript(transcript);
      };

      recognition.onerror = (event: any) => {
        clearTimeout(fallbackTimerRef.current);
        console.error("Speech recognition error:", event.error);
        if (event.error === 'not-allowed') {
          setLocation('朝阳公园');
          setTime('现在出发');
          setStep('confirming');
          stepRef.current = 'confirming';
          speakText("抱歉，没有麦克风权限，将使用默认地址朝阳公园。点击上半部分确认。");
        } else {
          setStep('idle');
          stepRef.current = 'idle';
          speakText("抱歉，没有听清，请点击屏幕重试。");
        }
      };
      
      recognition.onend = () => {
        if (stepRef.current === 'listening') {
           fallbackTimerRef.current = setTimeout(() => {
              if (stepRef.current === 'listening') {
                 processTranscript(""); // Force default
              }
           }, 500);
        }
      };

      recognition.start();
    } catch (err) {
      console.error("Failed to start speech recognition:", err);
      setLocation('朝阳公园');
      setTime('现在出发');
      setStep('confirming');
      stepRef.current = 'confirming';
      speakText("抱歉，语音识别启动失败，将使用默认地址朝阳公园。点击上半部分确认。");
    }
  };

  const startListening = () => {
    const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
    
    if (!SpeechRecognition) {
      setLocation('朝阳公园');
      setTime('现在出发');
      setStep('confirming');
      stepRef.current = 'confirming';
      speakText("抱歉，您的设备不支持语音识别，将使用默认地址朝阳公园。点击上半部分确认。");
      return;
    }
    
    setStep('prompting');
    stepRef.current = 'prompting'; // Synchronous update to prevent race conditions
    
    speakText("请说出您想去哪里跑步，以及什么时间", () => {
      // Start listening ONLY after the prompt finishes speaking
      if (stepRef.current !== 'prompting') return; // User might have navigated away or skipped
      
      startRecognition();
    });
  };

  const skipPrompt = () => {
    if ('speechSynthesis' in window) {
      window.speechSynthesis.cancel();
    }
    if (stepRef.current === 'prompting') {
      startRecognition();
    }
  };

  const stopListening = () => {
    if (recognitionRef.current && step === 'listening') {
      recognitionRef.current.stop();
      // Fallback if onresult doesn't fire
      fallbackTimerRef.current = setTimeout(() => {
        if (stepRef.current === 'listening') {
           processTranscript(""); // Force default
        }
      }, 1000);
    }
  };

  const handleSubmit = async () => {
    if (!user || !location || !time) return;

    setIsSubmitting(true);
    try {
      await addDoc(collection(db, 'runs'), {
        blindRunnerId: user.uid,
        volunteerId: null,
        status: 'pending',
        location,
        time,
        notes: null,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp()
      });
      
      speakText("预约成功，正在为您匹配志愿者。");
      
      navigate('/blind');
    } catch (error) {
      console.error("Error creating run:", error);
      setIsSubmitting(false);
    }
  };

  const handleRetry = () => {
    setLocation('');
    setTime('');
    setStep('idle');
    speakText("已取消，请重新点击屏幕开始语音预约。");
  };

  return (
    <div className="h-screen bg-black text-white flex flex-col font-sans overflow-hidden">
      <header className="p-4 flex justify-start">
        <button 
          onClick={() => navigate('/blind')}
          className="flex items-center gap-2 bg-zinc-800 text-zinc-300 px-6 py-4 rounded-2xl text-2xl font-bold active:scale-95 transition-transform"
        >
          <ArrowLeft size={32} />
          返回首页
        </button>
      </header>

      {step === 'idle' && (
        <button 
          onClick={startListening}
          className="flex-1 w-full bg-yellow-400 text-black flex flex-col items-center justify-center gap-8 active:scale-95 transition-transform p-8"
        >
          <Mic size={160} />
          <h1 className="text-7xl font-extrabold text-center leading-tight">点击屏幕<br/>开始语音预约</h1>
        </button>
      )}

      {step === 'prompting' && (
        <button 
          onClick={skipPrompt}
          className="flex-1 w-full bg-yellow-500 text-black flex flex-col items-center justify-center gap-8 p-8 active:scale-95 transition-transform"
        >
          <Volume2 size={160} className="animate-pulse" />
          <h1 className="text-7xl font-extrabold text-center leading-tight">正在播放提示音...<br/>请稍候</h1>
          <p className="text-3xl font-medium mt-4 opacity-70">(点击屏幕跳过)</p>
        </button>
      )}

      {step === 'listening' && (
        <button 
          onClick={stopListening}
          className="flex-1 w-full bg-emerald-500 text-black flex flex-col items-center justify-center gap-8 active:scale-95 transition-transform p-8 relative"
        >
          <div className="absolute inset-0 flex items-center justify-center opacity-20">
            <Waves size={300} className="animate-ping" />
          </div>
          <Mic size={160} className="z-10" />
          <h1 className="text-7xl font-extrabold text-center leading-tight z-10">正在倾听...<br/>请说话</h1>
          <p className="text-4xl font-medium mt-4 z-10">说完后点击屏幕停止</p>
          <p className="text-2xl font-medium mt-4 z-10 opacity-70">(如果卡住，请直接点击屏幕跳过)</p>
        </button>
      )}

      {step === 'confirming' && (
        <div className="flex-1 w-full flex flex-col">
          <button 
            onClick={handleSubmit}
            disabled={isSubmitting}
            className="flex-1 w-full bg-emerald-500 text-black flex flex-col items-center justify-center gap-6 active:scale-95 transition-transform p-8"
          >
            <CheckCircle size={100} />
            <h1 className="text-6xl font-extrabold text-center">确认预约</h1>
            <p className="text-4xl font-bold mt-2">{location} · {time}</p>
          </button>
          
          <button 
            onClick={handleRetry}
            disabled={isSubmitting}
            className="flex-1 w-full bg-red-500 text-white flex flex-col items-center justify-center gap-6 active:scale-95 transition-transform p-8"
          >
            <XCircle size={100} />
            <h1 className="text-6xl font-extrabold text-center">重新录音</h1>
          </button>
        </div>
      )}
    </div>
  );
}
