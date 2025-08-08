import React, { useState, useEffect, useCallback } from 'react';
import { useSpring, animated } from 'react-spring';
import SpaceMonster from './components/SpaceMonster';
import TodoInput from './components/TodoInput';
import TodoList from './components/TodoList';
import './App.css';

const App = () => {
  const [todos, setTodos] = useState([]);
  const [celebration, setCelebration] = useState(false);
  const [monsterMood, setMonsterMood] = useState('happy');
  const [spaceDebris, setSpaceDebris] = useState([]);
  const [cursorTrails, setCursorTrails] = useState([]);
  const [konami, setKonami] = useState([]);

  // Create floating space debris
  useEffect(() => {
    const createDebris = () => {
      const debris = [];
      for (let i = 0; i < 15; i++) {
        debris.push({
          id: i,
          size: Math.random() * 20 + 10,
          speed: Math.random() * 10 + 5,
          left: Math.random() * 100,
          top: Math.random() * 100,
          rotation: Math.random() * 360
        });
      }
      setSpaceDebris(debris);
    };

    createDebris();
  }, []);

  // Cursor trail effect
  const handleMouseMove = useCallback((e) => {
    const trail = {
      id: Date.now(),
      x: e.clientX,
      y: e.clientY
    };
    
    setCursorTrails(prev => [...prev.slice(-10), trail]);
    
    // Clean up old trails
    setTimeout(() => {
      setCursorTrails(prev => prev.filter(t => t.id !== trail.id));
    }, 1000);
  }, []);

  // Konami code easter egg
  useEffect(() => {
    const konamiCode = [
      'ArrowUp', 'ArrowUp', 'ArrowDown', 'ArrowDown',
      'ArrowLeft', 'ArrowRight', 'ArrowLeft', 'ArrowRight',
      'KeyB', 'KeyA'
    ];

    const handleKeyDown = (e) => {
      setKonami(prev => {
        const newSequence = [...prev, e.code];
        if (newSequence.length > konamiCode.length) {
          return newSequence.slice(-konamiCode.length);
        }
        
        if (newSequence.join('') === konamiCode.join('')) {
          document.body.classList.add('konami-activated');
          setTimeout(() => document.body.classList.remove('konami-activated'), 10000);
          return [];
        }
        
        return newSequence;
      });
    };

    document.addEventListener('keydown', handleKeyDown);
    document.addEventListener('mousemove', handleMouseMove);
    
    return () => {
      document.removeEventListener('keydown', handleKeyDown);
      document.removeEventListener('mousemove', handleMouseMove);
    };
  }, [handleMouseMove]);

  // Load todos from localStorage on mount
  useEffect(() => {
    const savedTodos = localStorage.getItem('cosmic-quest-todos');
    if (savedTodos) {
      try {
        setTodos(JSON.parse(savedTodos));
      } catch (error) {
        console.error('Error loading todos:', error);
      }
    }
  }, []);

  // Save todos to localStorage whenever todos change
  useEffect(() => {
    localStorage.setItem('cosmic-quest-todos', JSON.stringify(todos));
  }, [todos]);

  // Portal entrance animation
  const containerSpring = useSpring({
    from: { opacity: 0, transform: 'perspective(1000px) rotateX(90deg) scale(0.8)' },
    to: { opacity: 1, transform: 'perspective(1000px) rotateX(0deg) scale(1)' },
    config: { tension: 200, friction: 25 }
  });

  const addTodo = (text) => {
    const newTodo = {
      id: Date.now() + Math.random(),
      text: text.trim(),
      completed: false,
      createdAt: Date.now()
    };
    setTodos(prev => [...prev, newTodo]);
    setMonsterMood('excited');
    setTimeout(() => setMonsterMood('happy'), 3000);
  };

  const completeTodo = (id) => {
    setTodos(prev => prev.map(todo => 
      todo.id === id ? { ...todo, completed: true } : todo
    ));
    
    // Trigger epic celebration
    setCelebration(true);
    setMonsterMood('celebrating');
    
    // Screen flash effect
    document.body.style.background = 'radial-gradient(circle, rgba(0,255,255,0.3) 0%, rgba(255,0,255,0.3) 100%)';
    setTimeout(() => {
      document.body.style.background = '';
    }, 200);
    
    // Hide completed task after animation
    setTimeout(() => {
      setTodos(prev => prev.filter(todo => todo.id !== id));
      setCelebration(false);
      setMonsterMood('happy');
    }, 3000);
  };

  const activeTodos = todos.filter(todo => !todo.completed);

  return (
    <div className="app-container">
      {/* Floating Space Debris */}
      <div className="space-debris">
        {spaceDebris.map(debris => (
          <div
            key={debris.id}
            className="asteroid"
            style={{
              left: `${debris.left}%`,
              top: `${debris.top}%`,
              width: `${debris.size}px`,
              height: `${debris.size}px`,
              animationDuration: `${15 + debris.speed}s`,
              transform: `rotate(${debris.rotation}deg)`
            }}
          />
        ))}
      </div>

      {/* Cursor Trail Effects */}
      {cursorTrails.map(trail => (
        <div
          key={trail.id}
          className="cursor-trail"
          style={{
            left: trail.x - 10,
            top: trail.y - 10
          }}
        />
      ))}

      {/* Main Content */}
      <animated.div style={containerSpring} className="container py-5">
        <div className="row justify-content-center">
          <div className="col-lg-10">
            
            {/* Cosmic Header */}
            <div className="text-center mb-5">
              <h1 className="app-title">
                COSMIC QUEST TODO
              </h1>
              <SpaceMonster mood={monsterMood} />
            </div>

            {/* Mission Control Interface */}
            <div className="mb-5">
              <TodoInput onAddTodo={addTodo} />
            </div>

            {/* Active Missions */}
            <TodoList 
              todos={activeTodos} 
              onCompleteTodo={completeTodo}
            />

            {/* Cosmic Empty State */}
            {activeTodos.length === 0 && (
              <div className="text-center mt-5">
                <div className="empty-state">
                  <h3>🌌 ALL MISSIONS COMPLETE! 🌌</h3>
                  <p className="text-white-50 mb-0">
                    The cosmic realm awaits new adventures...<br/>
                    Initialize a new quantum mission to continue your journey!
                  </p>
                </div>
              </div>
            )}

          </div>
        </div>
      </animated.div>
    </div>
  );
};

export default App;