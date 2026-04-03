/** @type {import('next').NextConfig} */
// output:"standalone" is only needed for Docker/CI builds.
// Enabling it locally on Windows causes next build to hang during file-tracing.
const isCI = !!process.env.CI || process.env.NEXT_BUILD_STANDALONE === '1';
const nextConfig = {
  ...(isCI ? { output: 'standalone' } : {})
};

export default nextConfig;
