/* All API calls go to /api (relative) — CloudFront routes them to the ALB */
const API = '/api/tasks';

let tasks = [];

// ── DOM refs ──────────────────────────────────────────────────────────────────
const taskForm     = document.getElementById('taskForm');
const taskTitle    = document.getElementById('taskTitle');
const taskDesc     = document.getElementById('taskDesc');
const submitBtn    = document.getElementById('submitBtn');
const submitSpinner= document.getElementById('submitSpinner');
const formError    = document.getElementById('formError');
const globalError  = document.getElementById('globalError');
const taskList     = document.getElementById('taskList');
const loadingState = document.getElementById('loadingState');
const emptyState   = document.getElementById('emptyState');
const pendingCount = document.getElementById('pendingCount');
const doneCount    = document.getElementById('doneCount');

// ── API helpers ───────────────────────────────────────────────────────────────
async function apiCall(url, options = {}) {
  const res = await fetch(url, {
    headers: { 'Content-Type': 'application/json' },
    ...options
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ error: `HTTP ${res.status}` }));
    throw new Error(err.error || `HTTP ${res.status}`);
  }
  return res.json();
}

// ── Load tasks ────────────────────────────────────────────────────────────────
async function loadTasks() {
  try {
    tasks = await apiCall(API);
    showList();
  } catch (err) {
    showGlobalError(`Failed to load tasks: ${err.message}`);
    loadingState.classList.add('hidden');
  }
}

// ── Create task ───────────────────────────────────────────────────────────────
taskForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  const title = taskTitle.value.trim();
  const description = taskDesc.value.trim();
  if (!title) return;

  setSubmitting(true);
  hideFormError();

  try {
    const task = await apiCall(API, {
      method: 'POST',
      body: JSON.stringify({ title, description })
    });
    tasks.unshift(task);
    taskTitle.value = '';
    taskDesc.value = '';
    showList();
  } catch (err) {
    showFormError(`Failed to create task: ${err.message}`);
  } finally {
    setSubmitting(false);
  }
});

// ── Toggle complete ───────────────────────────────────────────────────────────
async function handleToggle(id, currentCompleted) {
  try {
    const updated = await apiCall(`${API}/${id}`, {
      method: 'PUT',
      body: JSON.stringify({ completed: !currentCompleted })
    });
    tasks = tasks.map(t => t.id === id ? updated : t);
    showList();
  } catch (err) {
    showGlobalError(`Failed to update task: ${err.message}`);
    showList(); // reset checkbox
  }
}

// ── Delete task ───────────────────────────────────────────────────────────────
async function handleDelete(id) {
  if (!confirm('Delete this task?')) return;
  try {
    await apiCall(`${API}/${id}`, { method: 'DELETE' });
    tasks = tasks.filter(t => t.id !== id);
    showList();
  } catch (err) {
    showGlobalError(`Failed to delete task: ${err.message}`);
  }
}

// ── Render ────────────────────────────────────────────────────────────────────
function showList() {
  loadingState.classList.add('hidden');
  hideGlobalError();

  const pending = tasks.filter(t => !t.completed).length;
  const done    = tasks.filter(t => t.completed).length;
  pendingCount.textContent = `${pending} pending`;
  doneCount.textContent    = `${done} done`;

  if (tasks.length === 0) {
    taskList.classList.add('hidden');
    emptyState.classList.remove('hidden');
    return;
  }

  emptyState.classList.add('hidden');
  taskList.classList.remove('hidden');

  taskList.innerHTML = tasks.map(task => `
    <li class="task-item ${task.completed ? 'completed' : ''}" data-id="${task.id}">
      <input type="checkbox" class="task-check" ${task.completed ? 'checked' : ''}
             onchange="handleToggle(${task.id}, ${task.completed})">
      <div class="task-body">
        <div class="task-title">${escapeHtml(task.title)}</div>
        ${task.description ? `<div class="task-desc">${escapeHtml(task.description)}</div>` : ''}
        <div class="task-meta">${formatDate(task.created_at)}</div>
      </div>
      <button class="delete-btn" onclick="handleDelete(${task.id})" title="Delete task">🗑️</button>
    </li>
  `).join('');
}

// ── Utilities ─────────────────────────────────────────────────────────────────
function setSubmitting(loading) {
  submitBtn.disabled = loading;
  submitSpinner.classList.toggle('hidden', !loading);
}

function showFormError(msg) {
  formError.textContent = msg;
  formError.classList.remove('hidden');
}

function hideFormError() {
  formError.classList.add('hidden');
}

function showGlobalError(msg) {
  globalError.textContent = msg;
  globalError.classList.remove('hidden');
}

function hideGlobalError() {
  globalError.classList.add('hidden');
}

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;')
    .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function formatDate(iso) {
  return new Date(iso).toLocaleDateString('en-US', {
    year: 'numeric', month: 'short', day: 'numeric',
    hour: '2-digit', minute: '2-digit'
  });
}

// ── Boot ──────────────────────────────────────────────────────────────────────
loadTasks();
