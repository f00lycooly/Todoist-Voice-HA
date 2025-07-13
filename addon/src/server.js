// src/server.js - Enhanced for Home Assistant Add-on with conversational capabilities
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const axios = require('axios');
const rateLimit = require('express-rate-limit');
const path = require('path');
const fs = require('fs');

const app = express();

const config = {
  port: process.env.PORT || 8080,
  nodeEnv: process.env.NODE_ENV || 'development',
  rateLimitWindow: parseInt(process.env.RATE_LIMIT_WINDOW) || 15,
  rateLimitMax: parseInt(process.env.RATE_LIMIT_MAX) || 200,
  corsOrigin: process.env.CORS_ORIGIN || '*',
  logLevel: process.env.LOG_LEVEL || 'info',
  defaultProjectName: process.env.DEFAULT_PROJECT_NAME || 'Inbox',
  defaultPriority: parseInt(process.env.DEFAULT_PRIORITY) || 2,
  defaultMainTaskPrefix: process.env.DEFAULT_MAIN_TASK_PREFIX || 'Voice Tasks',
  healthCheckTimeout: parseInt(process.env.HEALTH_CHECK_TIMEOUT) || 5000,
  trustedProxies: process.env.TRUSTED_PROXIES || '',
  version: process.env.npm_package_version || '2.0.0',
  todoistApiToken: process.env.TODOIST_API_TOKEN || null,
  // Home Assistant specific settings
  homeAssistantUrl: process.env.HOME_ASSISTANT_URL || 'http://supervisor/core',
  supervisorToken: process.env.SUPERVISOR_TOKEN || '',
  isHomeAssistantAddon: process.env.HOME_ASSISTANT_URL ? true : false
};

// Enhanced logging for Home Assistant Add-on
const createLogger = () => {
  const writeLog = (level, message, meta = {}) => {
    const logEntry = {
      timestamp: new Date().toISOString(),
      level,
      message,
      service: 'todoist-voice-ha',
      pid: process.pid,
      ...meta
    };
    
    const logLine = JSON.stringify(logEntry);
    console.log(logLine);
  };
  
  return {
    info: (message, meta = {}) => writeLog('info', message, meta),
    error: (message, error = {}, meta = {}) => writeLog('error', message, {
      error: error.message || error,
      stack: error.stack,
      ...meta
    }),
    warn: (message, meta = {}) => writeLog('warn', message, meta),
    debug: (message, meta = {}) => {
      if (config.logLevel === 'debug') {
        writeLog('debug', message, meta);
      }
    }
  };
};

const logger = createLogger();

// Project cache for dynamic project management
class ProjectCache {
  constructor() {
    this.projects = [];
    this.lastUpdated = null;
    this.cacheTimeout = 5 * 60 * 1000; // 5 minutes
  }

  isExpired() {
    if (!this.lastUpdated) return true;
    return Date.now() - this.lastUpdated > this.cacheTimeout;
  }

  async getProjects(forceRefresh = false) {
    if (forceRefresh || this.isExpired()) {
      await this.refreshCache();
    }
    return this.projects;
  }

  async refreshCache() {
    try {
      if (!config.todoistApiToken) {
        throw new Error('Todoist API token not configured');
      }

      const exporter = new TodoistExporter(config.todoistApiToken);
      this.projects = await exporter.getProjects();
      this.lastUpdated = Date.now();
      
      logger.info('Project cache refreshed', { 
        projectCount: this.projects.length,
        projectNames: this.projects.map(p => p.name)
      });

      // Notify Home Assistant of project list update if we're running as add-on
      if (config.isHomeAssistantAddon) {
        await this.notifyHomeAssistant();
      }

    } catch (error) {
      logger.error('Failed to refresh project cache', error);
      throw error;
    }
  }

  async notifyHomeAssistant() {
    try {
      // Update Home Assistant input_select with current projects
      const projectNames = this.projects.map(p => p.name);
      
      // This would be called via HA's REST API to update the input_select
      // We'll implement this when we create the HA integration configuration
      logger.debug('Would notify HA of project update', { projectNames });
      
    } catch (error) {
      logger.warn('Failed to notify Home Assistant of project update', error);
    }
  }

  findMatchingProjects(query) {
    if (!query || query.trim().length === 0) {
      return [];
    }

    const searchQuery = query.toLowerCase().trim();
    const matches = [];

    // Exact name match (highest priority)
    const exactMatch = this.projects.find(p => 
      p.name.toLowerCase() === searchQuery
    );
    if (exactMatch) {
      matches.push({ project: exactMatch, score: 100, reason: 'exact_match' });
    }

    // Starts with match
    const startsWithMatches = this.projects.filter(p => 
      p.name.toLowerCase().startsWith(searchQuery) && p.id !== exactMatch?.id
    );
    startsWithMatches.forEach(p => {
      matches.push({ project: p, score: 90, reason: 'starts_with' });
    });

    // Contains match
    const containsMatches = this.projects.filter(p => 
      p.name.toLowerCase().includes(searchQuery) && 
      !matches.some(m => m.project.id === p.id)
    );
    containsMatches.forEach(p => {
      matches.push({ project: p, score: 70, reason: 'contains' });
    });

    // Fuzzy/keyword matching for common terms
    const keywordMap = {
      'shop': ['shopping', 'shop', 'store', 'buy'],
      'work': ['work', 'office', 'job', 'task'],
      'home': ['home', 'house', 'personal'],
      'food': ['food', 'meal', 'cook', 'recipe', 'dinner', 'lunch'],
      'car': ['car', 'vehicle', 'auto', 'drive'],
      'health': ['health', 'doctor', 'medical', 'fitness'],
      'book': ['book', 'read', 'reading'],
      'movie': ['movie', 'film', 'watch', 'entertainment']
    };

    Object.entries(keywordMap).forEach(([category, keywords]) => {
      if (keywords.some(keyword => searchQuery.includes(keyword))) {
        const keywordMatches = this.projects.filter(p => 
          keywords.some(keyword => p.name.toLowerCase().includes(keyword)) &&
          !matches.some(m => m.project.id === p.id)
        );
        keywordMatches.forEach(p => {
          matches.push({ project: p, score: 60, reason: 'keyword_match' });
        });
      }
    });

    // Sort by score (highest first) and return top 5
    return matches
      .sort((a, b) => b.score - a.score)
      .slice(0, 5)
      .map(match => ({
        ...match.project,
        matchScore: match.score,
        matchReason: match.reason
      }));
  }

  generateProjectName(hint) {
    if (!hint) return 'New Project';
    
    // Clean and format the hint
    const cleaned = hint.trim()
      .replace(/^(my|the|a|an)\s+/i, '') // Remove articles
      .replace(/\s+/g, ' ') // Normalize spaces
      .split(' ')
      .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
      .join(' ');
    
    return cleaned || 'New Project';
  }
}

// Initialize project cache
const projectCache = new ProjectCache();

// CORS configuration
const corsOptions = {
  origin: (origin, callback) => {
    if (config.corsOrigin === '*') {
      callback(null, true);
    } else {
      const allowedOrigins = config.corsOrigin.split(',').map(o => o.trim());
      if (!origin || allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
};

app.use(cors(corsOptions));
app.use(express.json({ limit: '10mb' }));

// Security headers
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  next();
});

// Rate limiting
const limiter = rateLimit({
  windowMs: config.rateLimitWindow * 60 * 1000,
  max: config.rateLimitMax,
  message: {
    error: 'Too many requests',
    retryAfter: config.rateLimitWindow * 60,
    limit: config.rateLimitMax,
    window: config.rateLimitWindow
  },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    logger.warn('Rate limit exceeded', {
      ip: req.ip,
      userAgent: req.get('User-Agent'),
      path: req.path
    });
    res.status(429).json({
      error: 'Too many requests',
      retryAfter: config.rateLimitWindow * 60,
      message: `Rate limit exceeded. Try again in ${config.rateLimitWindow} minutes.`
    });
  }
});

app.use(limiter);

// Enhanced date parsing for Home Assistant integration
const parseDueDate = (dateInput) => {
  if (!dateInput) return null;
  
  const today = new Date();
  const input = dateInput.toLowerCase().trim();
  
  // Handle relative dates
  const dateMap = {
    'today': () => today.toISOString().split('T')[0],
    'tomorrow': () => {
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);
      return tomorrow.toISOString().split('T')[0];
    },
    'this week': () => {
      const friday = new Date(today);
      friday.setDate(today.getDate() + (5 - today.getDay()));
      return friday.toISOString().split('T')[0];
    },
    'next week': () => {
      const nextMonday = new Date(today);
      nextMonday.setDate(today.getDate() + (8 - today.getDay()));
      return nextMonday.toISOString().split('T')[0];
    }
  };

  if (dateMap[input]) {
    return dateMap[input]();
  }

  // Handle "in X days"
  const inDaysMatch = input.match(/in (\d+) days?/);
  if (inDaysMatch) {
    const days = parseInt(inDaysMatch[1]);
    const futureDate = new Date(today);
    futureDate.setDate(futureDate.getDate() + days);
    return futureDate.toISOString().split('T')[0];
  }

  // Handle day names
  const dayNames = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
  const dayMatch = dayNames.find(day => input.includes(day));
  if (dayMatch) {
    const targetDay = dayNames.indexOf(dayMatch);
    const currentDay = today.getDay();
    let daysToAdd = targetDay - currentDay;
    
    if (daysToAdd <= 0) {
      daysToAdd += 7;
    }
    
    const targetDate = new Date(today);
    targetDate.setDate(today.getDate() + daysToAdd);
    return targetDate.toISOString().split('T')[0];
  }

  // Handle YYYY-MM-DD format
  if (/^\d{4}-\d{2}-\d{2}$/.test(dateInput)) {
    return dateInput;
  }

  // Try to parse other date formats
  try {
    const parsed = new Date(dateInput);
    if (!isNaN(parsed)) {
      return parsed.toISOString().split('T')[0];
    }
  } catch (e) {
    // Ignore parsing errors
  }

  return null;
};

// Priority validation helper
const validatePriority = (priority) => {
  if (!priority) return 3;
  const p = parseInt(priority);
  if (p >= 1 && p <= 4) return p;
  return 3;
};

// Labels parsing helper
const parseLabels = (labels) => {
  if (!labels) return [];
  if (Array.isArray(labels)) {
    return labels.filter(label => typeof label === 'string' && label.trim().length > 0);
  }
  if (typeof labels === 'string') {
    return labels.split(',').map(l => l.trim()).filter(l => l.length > 0);
  }
  return [];
};

// Todoist API configuration
const TODOIST_API_BASE = 'https://api.todoist.com/rest/v2';

class TodoistExporter {
  constructor(apiToken) {
    this.apiToken = apiToken;
    this.headers = {
      'Authorization': `Bearer ${apiToken}`,
      'Content-Type': 'application/json',
      'User-Agent': `claude-todoist-addon/${config.version}`
    };
  }

  async validateToken() {
    try {
      const response = await axios.get(`${TODOIST_API_BASE}/projects`, {
        headers: this.headers,
        timeout: config.healthCheckTimeout
      });
      return { valid: true, projects: response.data };
    } catch (error) {
      logger.error('Token validation failed', error);
      return { 
        valid: false, 
        error: error.response?.data?.error || error.message 
      };
    }
  }

  async getProjects() {
    try {
      const response = await axios.get(`${TODOIST_API_BASE}/projects`, {
        headers: this.headers,
        timeout: config.healthCheckTimeout
      });
      return response.data;
    } catch (error) {
      logger.error('Failed to fetch projects', error);
      throw new Error(`Failed to fetch projects: ${error.response?.data?.error || error.message}`);
    }
  }

  async createProject(projectData) {
    try {
      const response = await axios.post(`${TODOIST_API_BASE}/projects`, projectData, {
        headers: this.headers,
        timeout: config.healthCheckTimeout
      });
      
      logger.info('Project created', { 
        projectId: response.data.id, 
        projectName: response.data.name 
      });
      
      // Refresh project cache after creation
      await projectCache.refreshCache();
      
      return response.data;
    } catch (error) {
      logger.error('Failed to create project', { projectData, error: error.message });
      throw new Error(`Failed to create project: ${error.response?.data?.error || error.message}`);
    }
  }

  async createTask(taskData) {
    try {
      const response = await axios.post(`${TODOIST_API_BASE}/tasks`, taskData, {
        headers: this.headers,
        timeout: config.healthCheckTimeout
      });
      return response.data;
    } catch (error) {
      logger.error('Failed to create task', { taskData, error: error.message });
      throw new Error(`Failed to create task: ${error.response?.data?.error || error.message}`);
    }
  }

  // Enhanced action extraction with better parsing
  extractActions(text) {
    const actionPatterns = [
      /(?:^|\n)\s*[-*•]\s*(.+?)(?=\n|$)/gm,
      /(?:^|\n)\s*\d+\.\s*(.+?)(?=\n|$)/gm,
      /(?:^|\n)\s*(?:TODO|Action|Task|Step)\s*:?\s*(.+?)(?=\n|$)/gmi,
      /(?:^|\n)\s*(?:You should|I recommend|Next step|Please|Consider|Make sure to|Don't forget to)\s+(.+?)(?=\n|$)/gmi,
      /(?:^|\n)\s*(?:Create|Build|Setup|Configure|Install|Update|Review|Analyze|Implement|Add|Remove|Fix|Test|Deploy|Write|Design|Plan|Research|Contact|Schedule|Book|Buy|Order|Call|Email|Send|Upload|Download|Backup|Delete|Archive|Organize|Clean|Prepare|Check|Verify|Validate|Monitor|Track|Document|Record|Report|Submit|Approve|Reject|Complete|Finish|Start|Begin|Launch|Stop|Pause|Resume|Cancel|Postpone|Reschedule)\s+(.+?)(?=\n|$)/gmi
    ];

    let actions = new Set();
    
    actionPatterns.forEach(pattern => {
      let match;
      while ((match = pattern.exec(text)) !== null) {
        const action = (match[1] || match[2] || '').trim();
        if (action.length > 3 && action.length < 500) {
          const cleanAction = action
            .replace(/^(that|to|and|or|but)\s+/i, '')
            .replace(/[.!?]+$/, '')
            .trim();
          
          if (cleanAction.length > 3) {
            actions.add(cleanAction);
          }
        }
      }
    });

    // Fallback: extract sentences with action verbs if no patterns match
    if (actions.size === 0) {
      const sentences = text.split(/[.!?]\s+/).filter(s => s.trim().length > 5);
      sentences.forEach(sentence => {
        const trimmed = sentence.trim();
        if (/^(create|make|build|setup|install|configure|update|review|analyze|implement|add|remove|fix|test|deploy|write|design|plan|research|contact|schedule|book|buy|order|call|email|send)/i.test(trimmed)) {
          if (trimmed.length < 500) {
            actions.add(trimmed);
          }
        }
      });
    }

    return Array.from(actions);
  }

  async exportToTodoist(options) {
    const {
      text,
      mainTaskTitle,
      projectId,
      priority = config.defaultPriority,
      dueDate,
      labels = [],
      autoExtract = true,
      manualActions = []
    } = options;

    let actions = [];
    if (autoExtract && text) {
      actions = this.extractActions(text);
    }
    if (manualActions && manualActions.length > 0) {
      actions = [...actions, ...manualActions];
    }

    if (actions.length === 0) {
      throw new Error('No actions found to export');
    }

    logger.info('Starting export', {
      actionsCount: actions.length,
      projectId,
      priority,
      mainTaskTitle
    });

    // Create main task
    const mainTaskData = {
      content: mainTaskTitle || `${config.defaultMainTaskPrefix} - ${new Date().toLocaleDateString()}`,
      project_id: projectId,
      priority: priority
    };

    if (dueDate) {
      mainTaskData.due_date = dueDate;
    }

    if (labels && labels.length > 0) {
      mainTaskData.labels = labels;
    }

    const mainTask = await this.createTask(mainTaskData);
    logger.info('Main task created', { taskId: mainTask.id, content: mainTask.content });

    // Create subtasks
    const subtasks = [];
    const failures = [];

    for (let i = 0; i < actions.length; i++) {
      try {
        const subtaskData = {
          content: actions[i],
          project_id: projectId,
          parent_id: mainTask.id,
          priority: priority
        };

        const subtask = await this.createTask(subtaskData);
        subtasks.push(subtask);
        
        // Small delay to avoid API rate limiting
        if (i < actions.length - 1) {
          await new Promise(resolve => setTimeout(resolve, 100));
        }
      } catch (error) {
        logger.error('Failed to create subtask', { action: actions[i], error: error.message });
        failures.push({
          action: actions[i],
          error: error.message
        });
      }
    }

    const result = {
      mainTask,
      subtasks,
      failures,
      summary: {
        totalActions: actions.length,
        successful: subtasks.length,
        failed: failures.length
      }
    };

    logger.info('Export completed', result.summary);
    return result;
  }
}

// ==========================================
// HOME ASSISTANT SPECIFIC API ENDPOINTS
// ==========================================

// Health check endpoint (enhanced for HA add-on)
app.get('/health', (req, res) => {
  const healthData = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: config.version,
    environment: config.nodeEnv,
    uptime: Math.floor(process.uptime()),
    isHomeAssistantAddon: config.isHomeAssistantAddon,
    projectCacheStatus: {
      projectCount: projectCache.projects.length,
      lastUpdated: projectCache.lastUpdated,
      isExpired: projectCache.isExpired()
    },
    memory: {
      used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
      total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024)
    },
    todoist: {
      tokenConfigured: !!config.todoistApiToken,
      apiStatus: 'unknown'
    }
  };
  
  res.json(healthData);
});

// ==========================================
// HOME ASSISTANT SERVICE ENDPOINTS
// ==========================================

// Service: Get Projects (for HA input_select updates)
app.get('/ha-services/projects', async (req, res) => {
  try {
    const projects = await projectCache.getProjects();
    
    res.json({
      success: true,
      projects: projects.map(p => ({
        id: p.id,
        name: p.name,
        isInbox: p.is_inbox_project || false,
        color: p.color,
        parentId: p.parent_id
      })),
      projectNames: projects.map(p => p.name),
      lastUpdated: projectCache.lastUpdated
    });

  } catch (error) {
    logger.error('Failed to get projects for HA', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
});

// Service: Find Matching Projects (for conversation flow)
app.post('/ha-services/find-projects', async (req, res) => {
  try {
    const { query, maxResults = 5 } = req.body;
    
    if (!query) {
      return res.status(400).json({
        success: false,
        error: 'Query parameter is required'
      });
    }

    await projectCache.getProjects(); // Ensure cache is fresh
    const matches = projectCache.findMatchingProjects(query);
    
    logger.info('Project search completed', {
      query,
      matchCount: matches.length,
      matches: matches.map(m => ({ name: m.name, score: m.matchScore }))
    });

    res.json({
      success: true,
      query,
      matches: matches.slice(0, maxResults),
      hasMatches: matches.length > 0,
      isAmbiguous: matches.length > 1,
      topMatch: matches.length > 0 ? matches[0] : null
    });

  } catch (error) {
    logger.error('Failed to find matching projects', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
});

// Service: Create New Project (for conversation flow)
app.post('/ha-services/create-project', async (req, res) => {
  try {
    const { name, color, parentId } = req.body;
    
    if (!name) {
      return res.status(400).json({
        success: false,
        error: 'Project name is required'
      });
    }

    if (!config.todoistApiToken) {
      return res.status(500).json({
        success: false,
        error: 'Todoist API token not configured'
      });
    }

    const exporter = new TodoistExporter(config.todoistApiToken);
    
    const projectData = {
      name: name.trim(),
      ...(color && { color }),
      ...(parentId && { parent_id: parentId })
    };

    const newProject = await exporter.createProject(projectData);
    
    logger.info('Project created via HA service', {
      projectId: newProject.id,
      projectName: newProject.name
    });

    res.json({
      success: true,
      project: {
        id: newProject.id,
        name: newProject.name,
        color: newProject.color,
        isInbox: newProject.is_inbox_project || false
      },
      message: `Project "${newProject.name}" created successfully`
    });

  } catch (error) {
    logger.error('Failed to create project via HA service', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
});

// Service: Suggest Project Name (for conversation flow)
app.post('/ha-services/suggest-project-name', (req, res) => {
  try {
    const { hint, context } = req.body;
    
    if (!hint) {
      return res.status(400).json({
        success: false,
        error: 'Hint parameter is required'
      });
    }

    const suggestedName = projectCache.generateProjectName(hint);
    
    logger.debug('Project name suggested', { hint, suggestedName, context });

    res.json({
      success: true,
      originalHint: hint,
      suggestedName,
      context
    });

  } catch (error) {
    logger.error('Failed to suggest project name', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
});

// Service: Parse Voice Input (for conversation analysis)
app.post('/ha-services/parse-voice-input', async (req, res) => {
  try {
    const { text, context = {} } = req.body;
    
    if (!text) {
      return res.status(400).json({
        success: false,
        error: 'Text parameter is required'
      });
    }

    // Parse the voice input for task extraction
    const exporter = new TodoistExporter('dummy'); // Token not needed for parsing
    const actions = exporter.extractActions(text);
    
    // Extract project hints
    const projectHints = [];
    const projectKeywords = [
      'list', 'project', 'tasks', 'shopping', 'work', 'home', 'personal',
      'diy', 'car', 'health', 'fitness', 'book', 'reading', 'movie'
    ];
    
    projectKeywords.forEach(keyword => {
      if (text.toLowerCase().includes(keyword)) {
        projectHints.push(keyword);
      }
    });

    // Extract date hints
    const dateHints = [];
    const dateKeywords = [
      'today', 'tomorrow', 'monday', 'tuesday', 'wednesday', 'thursday', 
      'friday', 'saturday', 'sunday', 'this week', 'next week'
    ];
    
    dateKeywords.forEach(keyword => {
      if (text.toLowerCase().includes(keyword)) {
        dateHints.push(keyword);
      }
    });

    // Extract priority hints
    let priorityHint = 3; // default
    if (text.toLowerCase().includes('urgent') || text.toLowerCase().includes('asap')) {
      priorityHint = 1;
    } else if (text.toLowerCase().includes('high priority') || text.toLowerCase().includes('important')) {
      priorityHint = 2;
    } else if (text.toLowerCase().includes('low priority') || text.toLowerCase().includes('sometime')) {
      priorityHint = 4;
    }

    const analysis = {
      originalText: text,
      extractedActions: actions,
      actionCount: actions.length,
      projectHints,
      dateHints,
      priorityHint,
      hasActions: actions.length > 0,
      needsProjectSelection: projectHints.length === 0,
      needsDateSelection: dateHints.length === 0,
      context
    };

    logger.info('Voice input parsed', {
      actionCount: actions.length,
      projectHints: projectHints.length,
      dateHints: dateHints.length,
      priority: priorityHint
    });

    res.json({
      success: true,
      analysis
    });

  } catch (error) {
    logger.error('Failed to parse voice input', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
});

// Service: Create Task with Conversation Context
app.post('/ha-services/create-task', async (req, res) => {
  try {
    const {
      text,
      projectId,
      projectName,
      priority = 3,
      dueDate,
      labels = ['voice', 'addon'],
      mainTaskTitle,
      conversationId
    } = req.body;

    if (!text && !mainTaskTitle) {
      return res.status(400).json({
        success: false,
        error: 'Either text or mainTaskTitle is required'
      });
    }

    if (!projectId && !projectName) {
      return res.status(400).json({
        success: false,
        error: 'Either projectId or projectName is required'
      });
    }

    if (!config.todoistApiToken) {
      return res.status(500).json({
        success: false,
        error: 'Todoist API token not configured'
      });
    }

    const exporter = new TodoistExporter(config.todoistApiToken);
    
    // If projectName provided instead of projectId, find the project
    let targetProjectId = projectId;
    if (!targetProjectId && projectName) {
      const projects = await projectCache.getProjects();
      const project = projects.find(p => 
        p.name.toLowerCase() === projectName.toLowerCase()
      );
      
      if (!project) {
        return res.status(400).json({
          success: false,
          error: `Project "${projectName}" not found`,
          availableProjects: projects.map(p => p.name)
        });
      }
      
      targetProjectId = project.id;
    }

    // Parse enhanced parameters
    const parsedDueDate = parseDueDate(dueDate);
    const validatedPriority = validatePriority(priority);
    const parsedLabels = parseLabels(labels);

    // Add conversation context to labels if provided
    if (conversationId) {
      parsedLabels.push(`conversation-${conversationId}`);
    }

    const result = await exporter.exportToTodoist({
      text,
      projectId: targetProjectId,
      mainTaskTitle: mainTaskTitle || `${config.defaultMainTaskPrefix} - ${new Date().toLocaleDateString()}`,
      priority: validatedPriority,
      dueDate: parsedDueDate,
      labels: parsedLabels,
      autoExtract: true
    });

    logger.info('Task created via HA service', {
      conversationId,
      projectId: targetProjectId,
      taskCount: result.summary.successful,
      mainTaskId: result.mainTask.id
    });

    res.json({
      success: true,
      mainTaskId: result.mainTask.id,
      subtaskCount: result.summary.successful,
      projectId: targetProjectId,
      priority: validatedPriority,
      dueDate: parsedDueDate,
      labels: parsedLabels,
      message: `Created 1 main task with ${result.summary.successful} subtasks`,
      failures: result.failures,
      conversationId
    });

  } catch (error) {
    logger.error('Failed to create task via HA service', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
});

// Service: Validate Date Input (for conversation flow)
app.post('/ha-services/validate-date', (req, res) => {
  try {
    const { dateInput, context } = req.body;
    
    const parsedDate = parseDueDate(dateInput);
    const isValid = parsedDate !== null;
    
    logger.debug('Date validation completed', {
      input: dateInput,
      parsed: parsedDate,
      isValid,
      context
    });

    res.json({
      success: true,
      originalInput: dateInput,
      parsedDate,
      isValid,
      humanReadable: isValid ? new Date(parsedDate).toLocaleDateString() : null,
      context
    });

  } catch (error) {
    logger.error('Failed to validate date', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
});

// Service: Refresh Project Cache (manual trigger)
app.post('/ha-services/refresh-projects', async (req, res) => {
  try {
    await projectCache.refreshCache();
    
    res.json({
      success: true,
      projectCount: projectCache.projects.length,
      lastUpdated: projectCache.lastUpdated,
      projects: projectCache.projects.map(p => p.name)
    });

  } catch (error) {
    logger.error('Failed to refresh project cache', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
});

// ==========================================
// LEGACY ENDPOINTS (maintain compatibility)
// ==========================================

// Enhanced GET projects-list endpoint
app.get('/projects-list', async (req, res) => {
  try {
    const projects = await projectCache.getProjects();
    
    res.json({
      success: true,
      projects: projects.map(p => ({
        id: p.id,
        name: p.name,
        isInbox: p.is_inbox_project || false
      })),
      cached: !projectCache.isExpired(),
      lastUpdated: projectCache.lastUpdated
    });

  } catch (error) {
    logger.error('Failed to get projects list', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
});

// Enhanced POST quick-export endpoint
app.post('/quick-export', async (req, res) => {
  try {
    const { 
      text, 
      projectName = config.defaultProjectName,
      mainTaskTitle,
      priority,
      dueDate,
      labels,
      conversationId
    } = req.body;

    if (!text) {
      return res.status(400).json({
        success: false,
        error: 'Text is required'
      });
    }

    if (!config.todoistApiToken) {
      return res.status(500).json({
        success: false,
        error: 'Todoist API token not configured'
      });
    }

    const exporter = new TodoistExporter(config.todoistApiToken);
    
    // Get projects and find the specified one
    const projects = await projectCache.getProjects();
    const project = projects.find(p => 
      p.name.toLowerCase() === projectName.toLowerCase() || 
      (projectName === 'Inbox' && p.is_inbox_project)
    );

    if (!project) {
      return res.status(400).json({ 
        success: false,
        error: `Project "${projectName}" not found. Available projects: ${projects.map(p => p.name).join(', ')}` 
      });
    }

    // Parse enhanced parameters
    const parsedDueDate = parseDueDate(dueDate);
    const validatedPriority = validatePriority(priority);
    const parsedLabels = parseLabels(labels);

    // Add conversation context if provided
    if (conversationId) {
      parsedLabels.push(`conversation-${conversationId}`);
    }

    const result = await exporter.exportToTodoist({
      text,
      projectId: project.id,
      mainTaskTitle: mainTaskTitle || `${config.defaultMainTaskPrefix} - ${new Date().toLocaleDateString()}`,
      priority: validatedPriority,
      dueDate: parsedDueDate,
      labels: parsedLabels,
      autoExtract: true
    });

    res.json({
      success: true,
      mainTaskId: result.mainTask.id,
      subtaskCount: result.summary.successful,
      projectName: project.name,
      priority: validatedPriority,
      dueDate: parsedDueDate,
      labels: parsedLabels,
      message: `Exported to ${project.name}: 1 main task with ${result.summary.successful} subtasks`,
      failures: result.failures,
      conversationId
    });

  } catch (error) {
    logger.error('Quick export failed', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
});

// Extract actions endpoint (preview)
app.post('/extract-actions', (req, res) => {
  try {
    const { text } = req.body;
    
    if (!text) {
      return res.status(400).json({ 
        success: false,
        error: 'Text is required' 
      });
    }

    const exporter = new TodoistExporter('dummy');
    const actions = exporter.extractActions(text);
    
    logger.info('Actions extracted', { 
      count: actions.length,
      ip: req.ip 
    });
    
    res.json({
      success: true,
      actions,
      count: actions.length,
      preview: actions.slice(0, 5)
    });
  } catch (error) {
    logger.error('Action extraction failed', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to extract actions' 
    });
  }
});

// ==========================================
// INITIALIZATION AND STARTUP
// ==========================================

// Initialize project cache on startup
async function initializeAddon() {
  logger.info('Initializing Todoist Voice HA Add-on', {
    version: config.version,
    environment: config.nodeEnv,
    isHomeAssistantAddon: config.isHomeAssistantAddon,
    tokenConfigured: !!config.todoistApiToken
  });

  if (config.todoistApiToken) {
    try {
      // Validate token and initialize project cache
      const exporter = new TodoistExporter(config.todoistApiToken);
      const validation = await exporter.validateToken();
      
      if (validation.valid) {
        await projectCache.refreshCache();
        logger.info('Add-on initialization successful', {
          projectCount: projectCache.projects.length
        });
      } else {
        logger.error('Todoist token validation failed', validation.error);
      }
    } catch (error) {
      logger.error('Failed to initialize add-on', error);
    }
  } else {
    logger.warn('Todoist API token not configured - some features will be unavailable');
  }
}

// Error handling middleware
app.use((error, req, res, next) => {
  logger.error('Unhandled error', error);
  res.status(500).json({ 
    success: false,
    error: 'Internal server error',
    message: config.nodeEnv === 'development' ? error.message : 'Something went wrong'
  });
});

// 404 handler
app.use((req, res) => {
  logger.warn('404 - Endpoint not found', { 
    url: req.url, 
    method: req.method,
    ip: req.ip 
  });
  res.status(404).json({ 
    success: false,
    error: 'Endpoint not found',
    availableEndpoints: [
      'GET /health',
      'GET /projects-list',
      'GET /ha-services/projects',
      'POST /ha-services/find-projects',
      'POST /ha-services/create-project',
      'POST /ha-services/suggest-project-name',
      'POST /ha-services/parse-voice-input',
      'POST /ha-services/create-task',
      'POST /ha-services/validate-date',
      'POST /ha-services/refresh-projects',
      'POST /quick-export',
      'POST /extract-actions'
    ]
  });
});

// Declare server variable
let server;

// Start server only if not in test environment
if (process.env.NODE_ENV !== 'test') {
  server = app.listen(config.port, '0.0.0.0', async () => {
    logger.info('Todoist Voice HA Add-on service started', {
      port: config.port,
      environment: config.nodeEnv,
      version: config.version,
      healthCheck: `http://localhost:${config.port}/health`,
      haServices: `http://localhost:${config.port}/ha-services/`,
      isHomeAssistantAddon: config.isHomeAssistantAddon
    });

    // Initialize the add-on
    await initializeAddon();
  });

  // Handle server errors
  server.on('error', (error) => {
    logger.error('Server error', error);
    process.exit(1);
  });

  // Graceful shutdown
  const gracefulShutdown = (signal) => {
    logger.info(`${signal} received, shutting down gracefully`);
    if (server) {
      server.close(() => {
        process.exit(0);
      });
    } else {
      process.exit(0);
    }
  };

  process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
  process.on('SIGINT', () => gracefulShutdown('SIGINT'));
}

// Export the app for testing
module.exports = app;