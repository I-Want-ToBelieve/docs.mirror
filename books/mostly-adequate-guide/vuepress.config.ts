import { type UserConfig, defineUserConfig } from 'vuepress'

const config: UserConfig = defineUserConfig({
  lang: 'en-US',
  title: 'mostly-adequate-guide',
  description: '',
  pagePatterns: ['**/*.md', '!**/README.md', '!.vuepress', '!node_modules']
})

export default config
