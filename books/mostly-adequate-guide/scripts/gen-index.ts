/* eslint-disable @typescript-eslint/explicit-function-return-type */
import * as fs from 'node:fs'
import * as path from 'node:path'
import { pipe, flow } from 'fp-ts/function'
import * as A from 'fp-ts/Array'
import * as T from 'fp-ts/Task'
import * as TE from 'fp-ts/TaskEither'
import * as Ord from 'fp-ts/Ord'
import { type Ordering } from 'fp-ts/Ordering'

const readDir: (
  path: string,
) => TE.TaskEither<NodeJS.ErrnoException, string[]> =
  TE.taskify(fs.readdir)
const readFile = TE.taskify(fs.readFile)
const writeFile = TE.taskify(fs.writeFile)
const readTextFile = flow(
  readFile,
  TE.map((buffer) => buffer.toString('utf-8'))
)

const modifyContent = (content: string) =>
  content
    .replace(/^(#{1,6}) /gm, (match, p1) => {
      const newLevel = p1 + '## '
      return newLevel
    })
    .replaceAll('src="images/', 'src="./images/')

const processFile = (docs: string) => (file: string) =>
  pipe(
    readTextFile(path.join(docs, file)),
    TE.map(modifyContent)
  )

const processFiles =
  (docs: string) => (excludeFiles: string[]) =>
    flow(
      A.filter(
        (file: string) =>
          file.endsWith('.md') &&
          !excludeFiles.includes(file)
      ),
      A.sort(
        Ord.fromCompare<string>((a, b) => {
          if (
            a.startsWith('ch') &&
            b.startsWith('appendix')
          ) {
            return -1
          }
          if (
            a.startsWith('appendix') &&
            b.startsWith('ch')
          ) {
            return 1
          }
          return a.localeCompare(b) as Ordering
        })
      ),
      A.map(processFile(docs)), // Call processFile with docs as argument
      A.sequence(TE.ApplicativePar)
    )

const writeIndex =
    (indexPath: string) => (content: string) =>
      pipe(
        writeFile(indexPath, content)
      )

export interface GenerateIndexParams {
  docsDir: string
  readmePath: string
  indexPath: string
  excludeFiles: string[]
}

const generateIndex = ({ docsDir, readmePath, indexPath, excludeFiles }: GenerateIndexParams) =>
  pipe(
    readDir(docsDir),
    TE.chain(processFiles(docsDir)(excludeFiles)),
    TE.chain((contents) =>
      pipe(
        readTextFile(readmePath),
        TE.map(
          (readme) => readme + '\n' + contents.join('\n')
        )
      )
    ),
    TE.chain(writeIndex(indexPath)),
    TE.fold(
      (err) => {
        console.error(err)
        return TE.right(undefined)
      },
      () => TE.right(undefined)
    )
  )

void pipe(
  generateIndex({
    docsDir: './docs',
    readmePath: path.join('./docs', 'README.md'),
    indexPath: path.join('./docs', 'index.md'),
    excludeFiles: ['FAQ.md', 'README.md', 'SUMMARY.md', 'TRANSLATIONS.md']
  }),
  TE.fold(
    (error) => T.fromIO(() => { console.error('Error generating index:', error) }),
    () => T.fromIO(() => { console.log('Index generation complete') })
  )
)()
