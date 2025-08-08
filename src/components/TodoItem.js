import React, { useState, useEffect } from 'react';
import { useSpring, animated } from 'react-spring';

const TodoItem = ({ todo, onComplete }) => {
  const [isHovered, setIsHovered] = useState(false);
  const [isCompleting, setIsCompleting] = useState(false);
  const [magneticEffect, setMagneticEffect] = useState({ x: 0, y: 0 });

  // Magnetic hover effect
  const magneticSpring = useSpring({
    transform: `translate3d(${magneticEffect.x}px, ${magneticEffect.y}px, 0) ${isHovered ? 'scale(1.02)' : 'scale(1)'}`,
    config: { tension: 300, friction: 20 }
  });

  // Completion animation
  const completionSpring = useSpring({
    opacity: isCompleting ? 0.8 : 1,
    transform: isCompleting ? 'scale(1.1) rotate(5deg)' : 'scale(1) rotate(0deg)',
    config: { tension: 300, friction: 20 }
  });

  const handleMouseMove = (e) => {
    if (!isHovered) return;
    
    const rect = e.currentTarget.getBoundingClientRect();
    const centerX = rect.left + rect.width / 2;
    const centerY = rect.top + rect.height / 2;
    
    const mouseX = e.clientX - centerX;
    const mouseY = e.clientY - centerY;
    
    // Create magnetic effect - stronger pull as mouse gets closer
    const maxDistance = 100;
    const distance = Math.sqrt(mouseX * mouseX + mouseY * mouseY);
    const magnetStrength = Math.max(0, 1 - distance / maxDistance);
    
    setMagneticEffect({
      x: mouseX * magnetStrength * 0.1,
      y: mouseY * magnetStrength * 0.1
    });
  };

  const handleMouseLeave = () => {
    setIsHovered(false);
    setMagneticEffect({ x: 0, y: 0 });
  };

  const handleComplete = () => {
    setIsCompleting(true);
    
    // Create explosion effect at button position
    const button = document.querySelector(`[data-todo-id="${todo.id}"] .complete-btn`);
    if (button) {
      const rect = button.getBoundingClientRect();
      const explosion = document.createElement('div');
      explosion.className = 'celebration-explosion';
      explosion.style.position = 'fixed';
      explosion.style.left = rect.left + rect.width / 2 + 'px';
      explosion.style.top = rect.top + rect.height / 2 + 'px';
      explosion.style.pointerEvents = 'none';
      explosion.style.zIndex = '9999';
      
      // Add particles
      for (let i = 0; i < 8; i++) {
        const particle = document.createElement('div');
        particle.className = 'particle';
        particle.style.setProperty('--angle', `${i * 45}deg`);
        explosion.appendChild(particle);
      }
      
      const wave = document.createElement('div');
      wave.className = 'rainbow-wave';
      explosion.appendChild(wave);
      
      document.body.appendChild(explosion);
      
      // Clean up after animation
      setTimeout(() => {
        document.body.removeChild(explosion);
      }, 3000);
    }
    
    setTimeout(() => {
      onComplete();
    }, 1000);
  };

  // Generate mission ID from todo ID
  const missionId = `QX-${todo.id.toString().slice(-4).toUpperCase()}`;

  return (
    <animated.div
      data-todo-id={todo.id}
      style={{ ...magneticSpring, ...completionSpring }}
      className="todo-item card border-0 portal-effect"
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={handleMouseLeave}
      onMouseMove={handleMouseMove}
    >
      <div className="card-body p-4">
        <div className="d-flex align-items-center">
          <button
            className="btn btn-outline-success btn-lg me-4 complete-btn"
            onClick={handleComplete}
            disabled={isCompleting}
            title="Complete Mission"
          >
            <span className="complete-icon">
              {isCompleting ? '💥' : '⚡'}
            </span>
          </button>
          
          <div className="flex-grow-1">
            <p className="todo-text mb-2">
              {todo.text}
            </p>
            <div className="d-flex align-items-center gap-2">
              <small className="text-white-50 font-monospace">
                🌌 MISSION ID: {missionId}
              </small>
              <small className="text-white-50">
                • STATUS: ACTIVE
              </small>
            </div>
          </div>
          
          <div className="todo-status">
            <span className="badge space-badge">
              ⚡ QUANTUM
            </span>
          </div>
        </div>
      </div>
      
      {/* Prismatic animated border */}
      <div className="todo-item-border" />
    </animated.div>
  );
};

export default TodoItem;