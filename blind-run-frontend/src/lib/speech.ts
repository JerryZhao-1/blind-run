export const speakText = (text: string, onEnd?: () => void) => {
  if (!('speechSynthesis' in window)) {
    if (onEnd) onEnd();
    return;
  }
  
  const synth = window.speechSynthesis;
  
  // Cancel previous utterances to prevent queue getting stuck
  synth.cancel();
  
  const utterance = new SpeechSynthesisUtterance(text);
  utterance.lang = 'zh-CN';
  utterance.rate = 1.0;
  
  let isFinished = false;
  
  const finish = () => {
    if (isFinished) return;
    isFinished = true;
    if (onEnd) onEnd();
  };
  
  utterance.onend = finish;
  
  utterance.onerror = (e) => {
    console.error("Speech synthesis error", e);
    finish();
  };
  
  // Prevent garbage collection bug in Chrome/Safari where the utterance is 
  // destroyed before it finishes speaking.
  (window as any)._currentUtterance = utterance;
  
  try {
    synth.speak(utterance);
  } catch (err) {
    console.error("Speech synthesis exception", err);
    finish();
  }
  
  // Fallback 1: Check if it actually started playing after a short delay.
  // If the browser blocks autoplay, it often silently drops the utterance 
  // without firing onend or onerror.
  setTimeout(() => {
    if (!isFinished && !synth.speaking && !synth.pending) {
      console.warn("Speech synthesis blocked by browser or finished silently.");
      finish();
    }
  }, 1000);
  
  // Fallback 2: Absolute maximum timeout based on text length
  // (approx 300ms per character + 2 seconds buffer)
  const maxTimeout = text.length * 300 + 2000;
  setTimeout(() => {
    if (!isFinished) {
      console.warn("Speech synthesis timeout reached, forcing completion.");
      finish();
    }
  }, maxTimeout);
};
