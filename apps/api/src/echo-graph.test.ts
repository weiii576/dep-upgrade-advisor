import { describe, expect, it } from 'vitest';
import { graph } from './echo-graph.js';

describe('echo graph', () => {
  it('returns the input state', async () => {
    const input = 'hello';
    const output = await graph.invoke({ messages: [{ role: "user", content: input }] });
    expect(output.messages[0].content).toEqual(input);
    expect(output.messages).toHaveLength(1)
  });
});
