# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Architecture

This is the **Space Monster Todo List** - a React-based animated todo application designed for live demonstrations. The project has a **dual architecture**:

### Development Architecture (src/ folder)
- **Component-based React app** using Create React App
- **React Spring animations** for 60fps smooth effects  
- **Bootstrap + custom CSS** for styling
- **localStorage persistence** for todo data
- **Interactive space monster mascot** with mood states

### Production Architecture (public/index.html)
- **Single-file HTML application** with embedded React via CDN
- **Self-contained** with all CSS and JavaScript inline
- **Deployed via Kubernetes ConfigMap** to your configured domain
- **Zero build dependencies** for production deployment

## Essential Commands

### Development
```bash
npm start              # Start dev server on localhost:3000
npm run build         # Create production build in build/
npm test              # Run test suite
```

### Deployment
**⚠️ IMPORTANT: Always ask for the target domain before starting deployment tasks**

Before running any deployment commands, you must:
1. **Ask the user for the FQDN (Fully Qualified Domain Name)** where the app will be deployed
2. **Set the DOMAIN environment variable**: `export DOMAIN="your-domain.com"`
3. **Verify the domain** is correctly configured in DNS and ingress

```bash
# Required before deployment:
export DOMAIN="your-domain.com"    # Set target domain

./deploy-simple.sh deploy          # Full deployment to Kubernetes  
./deploy-simple.sh update          # Quick ConfigMap update only
./deploy-simple.sh status          # Check deployment health
./deploy-simple.sh logs            # View application logs
```

### Testing
```bash
# UI testing with Playwright (if needed)
# Use mcp__playwright tools for comprehensive testing
```

## Key Application Components

### Core React Structure
- **App.js**: Main container with state management, localStorage, and easter eggs (Konami code)
- **SpaceMonster.js**: Animated mascot with mood states (happy, excited, celebrating)  
- **TodoInput.js**: Input field with space-themed styling
- **TodoList.js** & **TodoItem.js**: Task display with completion animations

### State Management Pattern
```javascript
// Todos stored in localStorage as 'cosmic-quest-todos' 
// Monster mood changes: happy -> excited (on add) -> celebrating (on complete)
// Celebration state triggers screen flash effects
```

### Animation System
- **React Spring** for physics-based animations
- **CSS animations** for background effects (starfield, debris)
- **60fps performance requirement** for live demos
- **Cursor trails** and **floating space debris** for ambiance

## Deployment Architecture 

### Domain Configuration Requirements
**🔴 CRITICAL: Always obtain target domain before deployment**

When asked to deploy the application:
1. **Ask**: "What domain will this be deployed to?" 
2. **Validate**: Confirm the FQDN format (e.g., `app.example.com`)
3. **Set Environment**: `export DOMAIN="user-provided-domain"`
4. **Update Manifests**: The ingress.yaml uses `${DOMAIN}` placeholder that gets replaced

### Kubernetes Structure
- **Namespace**: `space-monster-todo`
- **ConfigMap**: `space-monster-html` (contains public/index.html)
- **Deployment**: nginx:alpine pods serving static content
- **Service**: `space-monster-todo-service` on port 80
- **Ingress**: SSL/TLS termination with environment-configured domain

### Critical Files for Deployment
- **public/index.html**: Complete single-file application for production
- **k8s-configmap.yaml**: Generated ConfigMap for Kubernetes
- **deploy-simple.sh**: Automated deployment script
- **DEPLOYMENT.md**: Comprehensive deployment documentation

## Development Workflow

### Making Changes
1. Develop in `src/` folder using standard React patterns
2. Test locally with `npm start`
3. For production updates, modify `public/index.html` directly
4. Deploy using `./deploy-simple.sh update`

### Animation Performance
- All animations must maintain 60fps for live demo requirements
- Use `transform` and `opacity` for hardware acceleration
- Test animations on target demo hardware before deployment

### localStorage Integration
- Key: `'cosmic-quest-todos'` (not `'spaceTodos'` as in production HTML)
- JSON serialization with error handling
- Automatic save on todo state changes

## Important Considerations

### Live Demo Requirements
- **Zero-configuration startup** - must work perfectly on first run
- **Visual impact prioritized** - animations and effects are core features
- **Desktop-optimized** - not responsive for mobile
- **Performance critical** - tested for smooth 60fps animations

### Production vs Development Sync
The project maintains two versions:
- Development (`src/`) uses modular React components
- Production (`public/index.html`) is a single-file implementation
- **Keep both in sync** when making functional changes

### Kubernetes Deployment Notes
- Uses ConfigMap mounting instead of Docker builds for faster updates
- Nginx serves static content from mounted volume
- SSL handled by ingress controller with Let's Encrypt
- Deployment script handles ConfigMap updates and pod restarts

### Testing Strategy
- Functional testing via Playwright automation
- Visual verification of animations and effects
- localStorage persistence across browser sessions
- Edge case validation (empty input, special characters)

## Configuration Details

### Environment Variables
None required - application is fully self-contained.

### Dependencies
- **React 18.2.0** with Hooks
- **React Spring 9.7.0** for animations
- **Bootstrap 5.3.0** for base styling
- **UUID 9.0.0** for unique identifiers

### Browser Support
Optimized for modern browsers (Chrome, Firefox, Safari, Edge) with ES6+ support.