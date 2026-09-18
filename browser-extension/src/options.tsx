import React from 'react';
import { createRoot } from 'react-dom/client';

const Options: React.FC = () => {
  return (
    <div style={{ padding: 16 }}>
      <h1>ASH Options</h1>
      <p>Configure theme sync and API endpoint.</p>
      <label>API Base <input defaultValue="http://localhost:8787/api/v1" /></label>
    </div>
  );
};
const el = document.getElementById('root');
if (el) createRoot(el).render(<Options />);
export default Options;
