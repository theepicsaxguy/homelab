import React, { JSX } from 'react';
import Layout from '@theme/Layout';

import { HeroSection } from '../components/Homepage/HeroSection';
import { FeatureGrid } from '../components/Homepage/FeatureGrid';
import { QuickStart } from '../components/Homepage/QuickStart';
import { TechStack } from '../components/Homepage/TechStack';

export default function Home(): JSX.Element {
  return (
    <Layout
      title="Modern Homelab Infrastructure"
      description="A production-grade, GitOps-driven homelab built with Kubernetes, Talos, and modern DevOps practices"
    >
      <HeroSection />
      <FeatureGrid />
      <QuickStart />
      <TechStack />
    </Layout>
  );
}
