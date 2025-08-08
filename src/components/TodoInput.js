import React, { useState, useEffect, useRef } from 'react';
import { useSpring, animated } from 'react-spring';

const TodoInput = ({ onAddTodo }) => {
  const [inputValue, setInputValue] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const [showSoundWaves, setShowSoundWaves] = useState(false);
  const [glitchText, setGlitchText] = useState(false);
  const inputRef = useRef();
  const typingTimeoutRef = useRef();

  // Input glow animation
  const glowSpring = useSpring({
    boxShadow: isTyping 
      ? '0 0 30px rgba(255, 0, 255, 0.4), 0 0 60px rgba(0, 255, 255, 0.3)' 
      : '0 0 20px rgba(255, 0, 255, 0.2)',
    config: { tension: 300, friction: 20 }
  });

  // Sound wave animation
  useEffect(() => {
    if (isTyping) {
      setShowSoundWaves(true);
    } else {
      const timeout = setTimeout(() => setShowSoundWaves(false), 1000);
      return () => clearTimeout(timeout);
    }
  }, [isTyping]);

  // Random glitch effect
  useEffect(() => {
    const glitchInterval = setInterval(() => {
      if (Math.random() < 0.1) { // 10% chance every 2 seconds
        setGlitchText(true);
        setTimeout(() => setGlitchText(false), 300);
      }
    }, 2000);

    return () => clearInterval(glitchInterval);
  }, []);

  const handleSubmit = (e) => {
    e.preventDefault();
    if (inputValue.trim()) {
      onAddTodo(inputValue);
      setInputValue('');
      setIsTyping(false);
      
      // Trigger success animation
      if (inputRef.current) {
        inputRef.current.style.animation = 'portal-spawn 0.5s ease-out';
        setTimeout(() => {
          if (inputRef.current) {
            inputRef.current.style.animation = '';
          }
        }, 500);
      }
    }
  };

  const handleInputChange = (e) => {
    setInputValue(e.target.value);
    setIsTyping(true);
    
    // Reset typing state after user stops typing
    clearTimeout(typingTimeoutRef.current);
    typingTimeoutRef.current = setTimeout(() => {
      setIsTyping(false);
    }, 1000);
  };

  const handleFocus = () => {
    setIsTyping(true);
  };

  const handleBlur = () => {
    clearTimeout(typingTimeoutRef.current);
    setIsTyping(false);
  };

  return (
    <div className="todo-input-container">
      <animated.div style={glowSpring} className="input-glow-container">
        <form onSubmit={handleSubmit} className="d-flex gap-3 align-items-center">
          <div className="flex-grow-1 position-relative">
            <input
              ref={inputRef}
              type="text"
              className="form-control form-control-lg space-input"
              placeholder="⚡ ENTER QUANTUM MISSION PARAMETERS..."
              value={inputValue}
              onChange={handleInputChange}
              onFocus={handleFocus}
              onBlur={handleBlur}
              autoFocus
            />
            
            {/* Sound Wave Visualizer */}
            {showSoundWaves && (
              <div className="sound-waves">
                <div className="sound-bar"></div>
                <div className="sound-bar"></div>
                <div className="sound-bar"></div>
                <div className="sound-bar"></div>
                <div className="sound-bar"></div>
              </div>
            )}
          </div>
          
          <button
            type="submit"
            className="btn btn-primary btn-lg space-btn"
            disabled={!inputValue.trim()}
          >
            <span className="btn-text">INITIALIZE</span>
            <span className="btn-emoji">⚡</span>
          </button>
        </form>
      </animated.div>
      
      {/* Cyberpunk Hint */}
      <div className="input-hint text-center mt-3">
        <small className={`text-white-50 ${glitchText ? 'glitch-text' : ''}`}>
          💫 COSMIC COMMAND INTERFACE READY - PRESS ENTER TO EXECUTE 💫
        </small>
      </div>
    </div>
  );
};

export default TodoInput;