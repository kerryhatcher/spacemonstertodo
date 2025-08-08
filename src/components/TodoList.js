import React from 'react';
import { useTransition, animated } from 'react-spring';
import TodoItem from './TodoItem';

const TodoList = ({ todos, onCompleteTodo }) => {
  // Portal-style entrance/exit animations
  const transitions = useTransition(todos, {
    from: { 
      opacity: 0, 
      transform: 'perspective(1000px) rotateX(90deg) scale(0.5)',
      filter: 'blur(20px) hue-rotate(180deg)'
    },
    enter: { 
      opacity: 1, 
      transform: 'perspective(1000px) rotateX(0deg) scale(1)',
      filter: 'blur(0px) hue-rotate(0deg)'
    },
    leave: { 
      opacity: 0, 
      transform: 'perspective(1000px) rotateX(-90deg) scale(2)',
      filter: 'blur(20px) hue-rotate(360deg)'
    },
    keys: todo => todo.id,
    config: { tension: 200, friction: 25 }
  });

  if (todos.length === 0) {
    return null;
  }

  return (
    <div className="todo-list">
      <div className="mb-4">
        <h2 className="h4 text-white text-center mb-4" style={{
          fontFamily: 'Orbitron, monospace',
          textShadow: '0 0 10px rgba(0, 255, 255, 0.5)',
          letterSpacing: '2px'
        }}>
          ⚡ ACTIVE QUANTUM MISSIONS ⚡
        </h2>
      </div>
      
      {transitions((style, todo) => (
        <animated.div style={style} className="mb-4">
          <TodoItem
            todo={todo}
            onComplete={() => onCompleteTodo(todo.id)}
          />
        </animated.div>
      ))}
    </div>
  );
};

export default TodoList;