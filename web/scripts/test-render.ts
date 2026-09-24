import React from 'react';
import ReactDOMServer from 'react-dom/server';

// Mock localStorage if undefined
if (typeof window === 'undefined') {
  (global as any).window = undefined;
}

try {
  // Let's require the components using tsx
  console.log('Testing render of clinicalStore...');
  const { clinicalStore } = require('../lib/clinical-store.ts');
  console.log('clinicalStore metrics:', clinicalStore.getMetrics());
  console.log('clinicalStore patients:', clinicalStore.getPatients().length);
  console.log('clinicalStore screenings:', clinicalStore.getScreenings().length);

  console.log('Testing require of components...');
  const { AdminSidebar } = require('../components/AdminSidebar.tsx');
  const { AdminTopBar } = require('../components/AdminTopBar.tsx');
  const { DisclaimerBanner } = require('../components/DisclaimerBanner.tsx');
  const { DashboardView } = require('../components/DashboardView.tsx');

  console.log('Testing render of DashboardView...');
  const html = ReactDOMServer.renderToString(
    React.createElement(DashboardView, {
      onStartScreening: () => {},
      onOpenReview: () => {}
    })
  );
  console.log('DashboardView rendered successfully! Length:', html.length);

  console.log('Testing require of page.tsx...');
  const PageModule = require('../app/page.tsx');
  const HomePage = PageModule.default || PageModule;
  const pageHtml = ReactDOMServer.renderToString(React.createElement(HomePage));
  console.log('HomePage rendered successfully! Length:', pageHtml.length);

} catch (err) {
  console.error('SERVER RENDER ERROR:', err);
}
