import React, { useEffect, useState } from 'react';
import { useSpring, animated } from 'react-spring';

const SpaceMonster = ({ mood = 'happy' }) => {
  const [particles, setParticles] = useState([]);

  // Create bioluminescent particles
  useEffect(() => {
    const createParticles = () => {
      const newParticles = [];
      for (let i = 0; i < 12; i++) {
        newParticles.push({
          id: i,
          left: Math.random() * 100,
          delay: Math.random() * 6,
          size: Math.random() * 4 + 2
        });
      }
      setParticles(newParticles);
    };
    
    createParticles();
    const interval = setInterval(createParticles, 10000);
    return () => clearInterval(interval);
  }, []);

  // Mood-based transformations
  const moodSpring = useSpring({
    transform: mood === 'excited' ? 'scale(1.1)' : mood === 'celebrating' ? 'scale(1.2)' : 'scale(1)',
    filter: mood === 'celebrating' ? 'brightness(1.3) hue-rotate(45deg)' : 'brightness(1)',
    config: { tension: 300, friction: 20 }
  });

  const getMoodMessage = () => {
    switch (mood) {
      case 'excited':
        return "🌌 QUANTUM TASK DETECTED! PROCESSING... 🌌";
      case 'celebrating':
        return "💫 MISSION COMPLETE! ENERGY CORE CHARGED! 💫";
      default:
        return "🚀 COSMIC ENTITY ONLINE - READY FOR ADVENTURES! 🚀";
    }
  };

  return (
    <div className="space-monster-container text-center">
      <animated.div 
        style={moodSpring} 
        className="jellyfish-monster"
      >
        {/* Main Monster Body */}
        <div className="monster-body">
          {/* Energy Core */}
          <div className="energy-core"></div>
          
          {/* Multiple Blinking Eyes */}
          <div className="monster-eyes">
            <div className="eye"></div>
            <div className="eye"></div>
            <div className="eye"></div>
          </div>
        </div>

        {/* Animated Tentacles */}
        <div className="tentacles">
          <div className="tentacle"></div>
          <div className="tentacle"></div>
          <div className="tentacle"></div>
          <div className="tentacle"></div>
          <div className="tentacle"></div>
        </div>

        {/* Bioluminescent Particles */}
        <div className="bioluminescent-particles">
          {particles.map(particle => (
            <div
              key={particle.id}
              className="bio-particle"
              style={{
                left: `${particle.left}%`,
                animationDelay: `${particle.delay}s`,
                width: `${particle.size}px`,
                height: `${particle.size}px`
              }}
            />
          ))}
        </div>
      </animated.div>
      
      {/* Speech Bubble */}
      <div className="monster-speech-bubble">
        <div className="speech-bubble">
          <p className="mb-0 fw-bold">
            {getMoodMessage()}
          </p>
        </div>
      </div>

      {/* Epic Celebration Effects */}
      {mood === 'celebrating' && (
        <div className="celebration-explosion">
          <div className="particle"></div>
          <div className="particle"></div>
          <div className="particle"></div>
          <div className="particle"></div>
          <div className="particle"></div>
          <div className="particle"></div>
          <div className="particle"></div>
          <div className="particle"></div>
          <div className="rainbow-wave"></div>
        </div>
      )}
    </div>
  );
};

export default SpaceMonster;